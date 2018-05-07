require 'spec_helper'
require 'timeout'

describe CapybaraSpa::Server::NgStaticServer, js: true do
  let(:spec_dir) { File.join File.dirname(__FILE__), '../../' }
  let(:tmp_dir) { File.join spec_dir, '..', 'tmp' }
  let(:angular_app_path) { File.join tmp_dir, 'angular-app' }
  let(:angular_build_path) { File.join angular_app_path, 'dist/angular-app' }

  let(:server) do
    CapybaraSpa::Server::NgStaticServer.new(**server_args)
  end

  let(:default_constructor_args) do
    {
      build_path: angular_build_path
    }
  end
  let(:server_args) { default_constructor_args }

  def self.it_can_start_and_stop_a_static_server
    it 'can start and stop a static server' do
      begin
        started = server.start
        expect(started).to eq true
        expect(server.started?).to be true

        visit '/'
        expect(page).to have_content('Welcome to app!')

        pid_file = server.pid_file
        expect(File.exist?(pid_file)).to be true

        stopped = server.stop
        expect(stopped).to be true
        expect(server.stopped?).to be true
        expect(File.exist?(pid_file)).to_not be true
      ensure
        # if the test fails above we want to ensure the
        # server is stopped
        server.stop if server.started?
      end
    end
  end

  context 'with minimal options' do
    it_can_start_and_stop_a_static_server
  end

  context 'with a custom HTML tag' do
    let(:custom_tag) { 'my-app' }
    let(:default_tag) { 'app-root' }

    let(:index_file) { File.join(angular_build_path, 'index.html') }
    let!(:index_file_contents) { File.read(index_file) }

    around do |example|
      original_app_tag = CapybaraSpa.app_tag
      files_to_contents = {}
      begin
        CapybaraSpa.app_tag = custom_tag

        Dir.chdir(angular_build_path) do
          files = `grep -l app-root *`.split
          files.each do |file|
            files_to_contents[file] = File.read(file)
          end
          files_to_contents.each_pair do |file, contents|
            File.write(file, contents.gsub(/#{default_tag}/, custom_tag))
          end
        end
        Timeout.timeout(10) do
          example.run
        end
      ensure
        CapybaraSpa.app_tag = default_tag

        Dir.chdir(angular_build_path) do
          files_to_contents.each_pair do |file, contents|
            File.write(file, contents.gsub(/#{custom_tag}/, default_tag))
          end
        end
      end
    end

    it_can_start_and_stop_a_static_server
  end

  context 'with a custom build path' do
    let(:custom_build_path) { File.join angular_app_path, 'dist/my-custom-angular-app' }

    let(:server_args) do
      default_constructor_args.merge(build_path: custom_build_path)
    end

    around do |example|
      Dir.chdir(angular_app_path) do
        begin
          `mv #{angular_build_path} #{custom_build_path}`
          example.run
        ensure
          `mv #{custom_build_path} #{angular_build_path}`
        end
      end
    end

    it_can_start_and_stop_a_static_server
  end

  context 'when angular-http-server is not found' do
    let(:http_server_bin_path) { File.join(tmp_dir, 'non-existent', 'angular-http-server') }

    let(:server_args) do
      default_constructor_args.merge(http_server_bin_path: http_server_bin_path)
    end

    it 'raises an AngularHttpServerNotFound error' do
      expect do
        server.start
      end.to raise_error(CapybaraSpa::Server::NgStaticServer::NgHttpServerNotFound)
      expect(server.started?).to eq false
    end
  end

  context 'when angular-http-server is found, but not an executable' do
    let(:http_server_bin_path) { File.join(tmp_dir, 'non-executable-server') }

    let(:server_args) do
      default_constructor_args.merge(http_server_bin_path: http_server_bin_path)
    end

    around do |example|
      FileUtils.touch(http_server_bin_path)
      begin
        example.run
      ensure
        server.stop if server && server.started?
        FileUtils.rm(http_server_bin_path) if File.exist?(http_server_bin_path)
      end
    end

    it 'raises an NgStaticServerNotExecutable error' do
      expect do
        server.start
      end.to raise_error(CapybaraSpa::Server::NgStaticServer::NgHttpServerNotExecutable)
      expect(server.started?).to eq false
    end
  end

  context 'when the angular-app is not found/built' do
    let(:angular_app_path) { File.join tmp_dir, '/non-existent/angular-app' }

    let(:server_args) do
      default_constructor_args.merge(build_path: angular_app_path)
    end

    it 'prints an error' do
      expect do
        server.start
      end.to raise_error(CapybaraSpa::Server::NgStaticServer::NgAppNotFound)
      expect(server.started?).to eq false
    end
  end

  context 'with a custom log file' do
    let(:log_file) { File.join(tmp_dir, 'angular-http-server.log') }
    let(:server_args) do
      default_constructor_args.merge(log_file: log_file)
    end

    around do |example|
      FileUtils.touch log_file
      server.start
      begin
        example.run
      ensure
        server.stop if server && server.started?
        FileUtils.rm(log_file) if File.exist?(log_file)
      end
    end

    it 'logs out the angular-http-server output to the log file' do
      expect do
        visit '/'
      end.to change { File.read(log_file) }
    end
  end

  context 'with a custom pid file' do
    let(:custom_pid_file) { File.join(tmp_dir, 'angular-http-server.pid') }
    let(:server_args) { default_constructor_args.merge(pid_file: custom_pid_file) }

    before { server.start }
    after { server.stop }

    it 'writes out the PID of the angular-http-server process' do
      expect(File.exist?(custom_pid_file)).to be true
      pid =  File.read(custom_pid_file).to_i

      # pid should not be zero
      expect(pid).to be > 0

      expect do
        # Ensure process is running, will raise error if it's not
        Process.kill 'SIGHUP', pid
      end.to_not raise_error
    end
  end
end
