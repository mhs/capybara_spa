require File.join(File.dirname(__FILE__), 'capybara_spa/capybara_dsl_ext')
require File.join(File.dirname(__FILE__), 'capybara_spa/server/ng_static_server')

module CapybaraSpa
  class << self
    #  * NG_APP_TAG: the HTML tag where the angular app is stored. Defaults to app-root.
    attr_accessor :app_tag

    #  * NG_LOG_FILE: where to log the output of angular-http-server. Defaults to /dev/null
    attr_accessor :log_file
  end

  self.app_tag = ENV.fetch('NG_APP_TAG', 'app-root')
  self.log_file = ENV.fetch('NG_LOG_FILE', '/dev/null')

  module Server
  end
end