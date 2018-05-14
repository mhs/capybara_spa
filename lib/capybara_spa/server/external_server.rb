require 'socket'
require 'timeout'

module CapybaraSpa
  module Server
    class ExternalServerNotFoundOnPort < Error ; end
    class ExternalServerStillRunning < Error ; end

    # CapybaraSpa::Server::ExternalServer is a class that wraps a server running as
    # as an external process. For example, let's say you wanted to always have an
    # a version of your single-page-application up and running for integration tests.
    # You would start this in a different terminal or shell like this:
    #
    #     ng serve --port 5001
    #
    # Then you would configure your CapybaraSpa server in your test helper (e.g. \
    # spec_helper.rb, rails_helper.rb, etc):
    #
    #   server = CapybaraSpa::Server::ExternalServer.new(
    #     port: 5001
    #   )
    #
    class ExternalServer
      # +host+ is a string of the host or ip address to connect to
      attr_accessor :host

      # +port+ is port number that the external process is running on
      attr_accessor :port

      # +start_timeout+ is the number of seconds to wait for the external process
      # to begin listening on +port+. Applies to #start and #started?
      attr_accessor :start_timeout

      # +stop_timeout+ is the number of seconds to wait when determining the external
      # process is no longer running. Applies to #stop and #stopped?
      attr_accessor :stop_timeout

      def initialize(host: 'localhost', port: 5001, start_timeout: 60, stop_timeout: 1)
        @host = host
        @port = port
        @start_timeout = start_timeout
        @stop_timeout = stop_timeout
      end

      # +start+ is a no-op, but it will wait up to the +start_timeout+ for the external
      # process to start listening on the specified +port+ before giving up and raising
      # an ExternalServerNotFoundOnPort error.
      def start
        unless is_port_open?(timeout: start_timeout)
          raise ExternalServerNotFoundOnPort, <<-ERROR.gsub(/^\s*\|/, '')
            |Tried for #{start_timeout} seconds but nothing was listening
            |on port #{port}. Please make sure the external process is running
            |successfully and that the port is correct.
          ERROR
        end
      end

      # Returns true if the an external process is running on the +host+ and +port+.
      # Otherwise, returns false.
      def started?
        is_port_open?(timeout: start_timeout)
      end

      # +stop+ is a no-op, but it will wait up to the +stop_timeout+ for the external
      # process to stop listening on the specified +port+ before giving up
      # and raising an ExternalServerStillRunning error.
      def stop
        unless !is_port_open?(timeout: stop_timeout)
          raise ExternalServerStillRunning, <<-ERROR.gsub(/^\s*\|/, '')
            |I tried for #{stop_timeout} seconds to verify that the
            |external process listening on #{port} had stopped listening,
            |but it hasn't. You may have a zombie process
            |or may need to increase the stop_timeout.
          ERROR
        end
      end

      # Returns true if the an external process is not running on the +host+ and +port+.
      # Otherwise, returns true.
      def stopped?
        !is_port_open?(timeout: stop_timeout)
      end

      private

      def is_port_open?(timeout: 10)
        Timeout.timeout(timeout) do
          begin
            s = TCPSocket.new(host, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            sleep 1
            retry
          end
        end
      rescue Timeout::Error
        return false
      end
    end
  end
end