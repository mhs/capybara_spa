require 'logger'

module CapybaraSpa
  module Server
    class Error < ::StandardError ; end

    # CapybaraSpa::Server::NgStaticServer is a class that wraps running
    # a static Angular app using angular-http-server. It can take the
    # following environment variables:
    #
    #  * NG_BUILD_PATH: where the angular app has been built to. Defaults to nil.
    #  * NG_HTTP_SERVER_BIN: where angular-http-server binary/script is located. Defaults to nil \
    #      which will force lookup of it in PATH, then in node_modules/.
    #  * NG_PID_FILE: where to write a PID file to. Defaults to /tmp/angular-process.pid
    #  * NG_PORT: what port to run the Angular app on. Defaults to 5001.
    #
    class NgStaticServer
      class NgAppNotFound < Error ; end
      class NgHttpServerNotFound < Error ; end
      class NgHttpServerNotExecutable < Error ; end
      class NodeModulesDirectoryNotFound < Error ; end

      attr_accessor :build_path, :http_server_bin_path, :log_file, :pid_file, :port
      attr_accessor :pid

      def initialize(build_path: nil, http_server_bin_path: nil, log_file: CapybaraSpa.log_file, pid_file: nil, port: nil)
        build_path ||= ENV.fetch('NG_BUILD_PATH', nil)
        @build_path = File.expand_path(build_path) if build_path
        @built = false
        @http_server_bin_path = http_server_bin_path || ENV.fetch('NG_HTTP_SERVER_BIN') { find_http_server_bin_path }
        @log_file = log_file
        @pid_file = pid_file || ENV.fetch('NG_PID_FILE', '/tmp/angular-process.pid')
        @port = port || ENV.fetch('NG_PORT', 5001)
        @started = false
      end

      def build(&blk)
        @built ||= begin
          yield
          true
        end
      end

      def built?
        @built
      end

      def started?
        @started
      end

      def stopped?
        !@started
      end

      def start
        return false if started?

        check_requirements!

        @pid = fork do
          STDOUT.reopen(@log_file) unless @log_file == STDOUT
          run_server
        end
        File.write(pid_file, pid)

        at_exit { stop }
        @started = true
      end

      def stop
        if File.exist?(pid_file)
          pid = File.read(pid_file).to_i
          puts "capybara_spa/angular-http-server:parent#at_exit sending SIGTERM to pid: #{pid}" if ENV['DEBUG']
          begin
            Process.kill 'SIGTERM', pid
            Process.wait pid
          rescue Errno::ECHILD => ex
            # no-op, the child process does not exist
          end

          puts "capybara_spa/angular-http-server removing pid_file: #{pid_file}" if ENV['DEBUG']
          FileUtils.rm pid_file
          @started = false
          true
        else
          puts "capybara_spa/angular-http-server did not find pid_file, no process to SIGHUP: #{pid_file}" if ENV['DEBUG']
          false
        end
      end

      private

      def check_requirements!
        check_executable_requirements!
        check_ng_app_requirements!
      end

      def check_executable_requirements!
        executable_name = File.basename(http_server_bin_path)
        if File.exist?(http_server_bin_path)
          if !File.executable?(http_server_bin_path)
            raise NgHttpServerNotExecutable, 'File found, but not executable!'
          end
        else
          error_message = <<-ERROR.gsub(/^\s*\|/, '')
            |#{executable_name + ' not found!'} Make sure it's installed via npm:
            |
            |To the project:
            |
            |   npm install --save-dev #{executable_name}
            |
            |Or globally:
            |
            |   npm install -g #{executable_name}
            |
          ERROR
          raise NgHttpServerNotFound, error_message
        end
      end

      def check_ng_app_requirements!
        unless Dir.exist?(build_path)
          error_message = <<-ERROR.gsub(/^\s*\|/, '')
            |#{File.expand_path(build_path)} directory not found! Make sure the angular app is being built:
            |
            |Angular 5 example:
            |   ng build --aot --environment e2e --target=development --output-path=public/app/
            |
            |Angular 6 example:
            |   ng build --aot --configuration e2e --output-path=public/app/
            |
          ERROR
          raise NgAppNotFound, error_message
        end
      end

      def find_http_server_bin_path
        http_server_bin_path = `which angular-http-server`.chomp

        # if no http-server found in default PATH then try to find it in node_modules
        if http_server_bin_path.length == 0
          http_server_bin_path = File.join(node_modules_path, '.bin', 'angular-http-server')
        end

        File.expand_path(http_server_bin_path) if http_server_bin_path
      end

      def node_modules_path
        cwd = ''
        loop do
          path = File.expand_path File.join(build_path, cwd, 'node_modules')
          if Dir.exist?(path)
            return path
          elsif File.expand_path(path) == '/node_modules'
            raise NodeModulesDirectoryNotFound, 'Cannot find "node_modules" directory. Walked all the way to the root "/"!'
          else
            cwd = File.join '..', cwd
          end
        end
      end

      def run_server
        build_dir = File.dirname(build_path)
        Dir.chdir(build_dir) do
          cmd = [http_server_bin_path, "-p", port, "--path", File.basename(build_path)]
          puts "capybara_spa/angular-http-server is executing command: #{cmd.join(' ')}" if ENV['DEBUG']
          spawn_cmd(cmd)
        end
      end

      def spawn_cmd(cmd)
        puts "capybara_spa/angular-http-server is executing command: #{cmd}" if ENV['DEBUG']

        # use spawn(cmd, arg1, ... ) version to avoid launching a shell that launches the
        # http-server or ng process. We want this pid to be the actual process to kill when
        # this program is done exiting.
        pid = spawn *cmd

        puts "capybara_spa/angular-http-server:forked child with pid: #{pid}" if ENV['DEBUG']

        at_exit do
          puts "capybara_spa/angular-http-server:forked#at_exit is sending SIGTERM signal to pid: #{pid}" if ENV['DEBUG']
          begin
            Process.kill 'TERM', pid
            Process.wait pid
          rescue Errno::ESRCH
            # no-op: the process is already dead
          end
        end

        Process.waitall
      end
    end
  end
end
