module CapybaraSpa
  class << self
    # +app_tag+ is the HTML tag where the single page application is stored. Defaults to app-root. \
    #   This can be set thru the SPA_APP_TAG environment variable.
    attr_accessor :app_tag

    # +log_file+ where to log the output of angular-http-server. Defaults to /dev/null \
    #   This can be set thru the SPA_LOG_FILE environment variable.
    attr_accessor :log_file
  end

  self.app_tag = ENV.fetch('SPA_APP_TAG', 'app-root')
  self.log_file = ENV.fetch('SPA_LOG_FILE', STDOUT)
end

require File.join(File.dirname(__FILE__), 'capybara_spa/capybara_dsl_ext')
require File.join(File.dirname(__FILE__), 'capybara_spa/server')
require File.join(File.dirname(__FILE__), 'capybara_spa/server/external_server')
require File.join(File.dirname(__FILE__), 'capybara_spa/server/ng_static_server')
