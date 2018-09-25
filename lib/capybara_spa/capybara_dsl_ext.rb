require 'capybara/dsl'

module Capybara
  module DSL
    def page
      wait_until_single_page_app_is_found unless @ignoring_single_page_app
      Capybara.current_session
    end

    def wait_until_single_page_app_is_found
      return if CapybaraSpa.single_page_app_found

      single_page_app_found = false

      loop do
        Capybara.current_session.visit('/')
        app_tag = CapybaraSpa.app_tag
        single_page_app_found = Capybara.current_session.evaluate_script <<-JAVASCRIPT
          document.getElementsByTagName('#{app_tag}').length === 1
        JAVASCRIPT
        CapybaraSpa.single_page_app_found = single_page_app_found
        break if CapybaraSpa.single_page_app_found
        sleep 0.25
      end
    end

    def ignoring_angular(&block)
      ignoring_single_page_app(&block)
    end

    def ignoring_single_page_app(&block)
      @ignoring_single_page_app = true
      yield
    ensure
      @ignoring_single_page_app = false
    end
  end
end
