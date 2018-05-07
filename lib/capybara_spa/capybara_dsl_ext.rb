require 'capybara/dsl'

module Capybara
  module DSL
    def page
      wait_until_angular_app_is_found unless @ignoring_angular
      Capybara.current_session
    end

    def wait_until_angular_app_is_found
      return if @angular_app_found

      @angular_app_found = false

      loop do
        Capybara.current_session.visit('/')
        app_tag = CapybaraSpa.app_tag
        @angular_app_found = Capybara.current_session.evaluate_script <<-JAVASCRIPT
          document.getElementsByTagName('#{app_tag}').length === 1
        JAVASCRIPT
        break if @angular_app_found
        sleep 0.25
      end
    end

    def ignoring_angular
      @ignoring_angular = true
      yield
    ensure
      @ignoring_angular = false
    end
  end
end
