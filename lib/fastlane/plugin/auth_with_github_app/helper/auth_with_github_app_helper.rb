require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class AuthWithGithubAppHelper
      # class methods that you define here become available in your action
      # as `Helper::AuthWithGithubAppHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the auth_with_github_app plugin helper!")
      end
    end
  end
end
