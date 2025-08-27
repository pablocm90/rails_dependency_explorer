# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyExplorerRailsConfigurationTest < Minitest::Test
  def test_dependency_explorer_tracks_configuration_dependencies
    ruby_code = <<~RUBY
      class ApplicationService
        def initialize
          @logger = Rails.logger
          @env = Rails.env
          @config = Rails.application.config
          @root_path = Rails.root
          @cache = Rails.cache
          @api_key = ENV['API_KEY']
          @secret = Rails.application.secrets.secret_key_base
          @credentials = Rails.application.credentials.database_password
        end

        def development?
          Rails.env.development?
        end

        def production_config
          Rails.application.config.force_ssl if Rails.env.production?
        end
      end
    RUBY

    explorer = RailsDependencyExplorer::Analysis::Pipeline::DependencyExplorer.new
    result = explorer.analyze_code(ruby_code)

    # Should track Rails configuration dependencies
    config_dependencies = result.rails_configuration_dependencies

    expected_dependencies = {
      "ApplicationService" => {
        rails_config: ["Rails.logger", "Rails.env", "Rails.application.config", "Rails.root", "Rails.cache"],
        environment_variables: ["ENV"],
        secrets_and_credentials: []
      }
    }

    assert_equal expected_dependencies, config_dependencies
  end
end
