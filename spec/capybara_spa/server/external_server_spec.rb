require 'spec_helper'
require 'timeout'

describe CapybaraSpa::Server::ExternalServer, js: true do
  let(:spec_dir) { File.expand_path File.join(File.dirname(__FILE__), '../../') }
  let(:tmp_dir) { File.expand_path File.join(spec_dir, '..', 'tmp') }
  let(:angular_app_path) { File.join spec_dir, 'angular-app' }
  let(:node_modules_path) {  File.join angular_app_path, 'node_modules' }
  let(:ng_bin_path) { File.join node_modules_path, '.bin/ng' }

  let(:server) do
    CapybaraSpa::Server::ExternalServer.new(server_args)
  end

  let(:default_constructor_args) { {} }
  let(:server_args) { default_constructor_args }

  def spawn_cmd(cmd)
    # use spawn(cmd, arg1, ... ) version to avoid launching a shell that launches the
    # http-server or ng process. We want this pid to be the actual process to kill when
    # this program is done exiting.
    pid = spawn *cmd.split(/\s+/)

    at_exit do
      begin
        Process.kill 'TERM', pid
        Process.wait pid
      rescue Errno::ECHILD, Errno::ESRCH
        # no-op: the process is already dead
      end
    end

    pid
  end

  context 'when no external process is running on the given port' do
    it 'can tell you that the process is not running' do
      server.start_timeout = 1
      expect(server.started?).to be false

      server.stop_timeout = 1
      expect(server.stopped?).to be true
    end

    it 'raises an exception when it cannot connect to the server by +start_timeout+ seconds' do
      server.start_timeout = 0.25
      expect do
        server.start
      end.to raise_error CapybaraSpa::Server::ExternalServerNotFoundOnPort
    end
  end

  context 'when running against a running process on a given port' do
    let(:server_args) { { port: 5001 } }

    around do |example|
      pid = Dir.chdir angular_app_path do
        spawn_cmd "#{ng_bin_path} serve --port 5001"
      end

      begin
        example.run
      ensure
        (Process.kill 'TERM', pid rescue Errno::ESRCH) if pid
      end
    end

    it 'can tell you that the process is running' do
      expect(server.started?).to be true
      expect(server.stopped?).to be false
    end

    it 'can run Capybara tests against the running process' do
      visit '/'
      expect(page).to have_content('Welcome to app!')
    end

    it 'raises an exception when told the server has stopped and it does not stop within +stop_timeout+ seconds' do
      server.stop_timeout = 0.25
      expect do
        server.stop
      end.to raise_error CapybaraSpa::Server::ExternalServerStillRunning
    end
  end
end
