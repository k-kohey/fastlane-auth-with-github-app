require 'fastlane/action'
require_relative '../helper/auth_with_github_app_helper'
require 'openssl'
require 'jwt'

module Fastlane
  module Actions
    class AuthWithGithubAppAction < Action
      def self.run(params)
        private_pem = params[:pem]
        app_id = params[:app_id]
        installation_id = params[:installation_id]

        private_key = OpenSSL::PKey::RSA.new(private_pem)

        payload = {
          # issued at time, 60 seconds in the past to allow for clock drift
          iat: Time.now.to_i - 60,
          # JWT expiration time (10 minute maximum)
          exp: Time.now.to_i + (10 * 60),
          # GitHub App's identifier
          iss: app_id
        }

        jwt = JWT.encode(payload, private_key, "RS256")

        uri = URI.parse("https://api.github.com/app/installations/#{installation_id}/access_tokens")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        headers = { Authorization: "Bearer #{jwt}", Accept: "application/vnd.github+json", 'User-Agent': "auth_with_github_app" }
        req = Net::HTTP::Post.new(uri.path)
        req.initialize_http_header(headers)
        response = http.request(req)

        if response.code.to_i < 200 || response.code.to_i > 299
          UI.error("HTTP request to GitHub failed with status code #{response.code}\n detail: #{response.body}")
          exit(1)
        end

        token = JSON.parse(response.body)['token']
        if token == "" || token.nil?
          UI.error("The Token obtained is empty; the response from the API may be invalid.")
          exit(1)
        end

        return token
      end

      def self.description
        "Get a GitHub access token using the GitHub App"
      end

      def self.authors
        ["k-kohey"]
      end

      def self.return_value
        "API Token obtained using the GitHub App."
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :pem,
                                       env_name: "GITHUB_APP_PEM",
                                       description: "Private key available from the GitHub App administration screen",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :app_id,
                                       env_name: "GITHUB_APP_ID",
                                       description: "App ID available from the GitHub App administration screen",
                                       optional: false,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :installation_id,
                                       env_name: "GITHUB_APP_INSTLLATION_ID",
                                       description: "Installation id available from the GitHub App administration screen",
                                       optional: false,
                                       type: Integer)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
