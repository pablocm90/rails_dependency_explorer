# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class NamespaceAwareParsingTest < Minitest::Test
  def test_parses_nested_module_classes_with_full_namespace
    ruby_code = <<~RUBY
      module App
        module Models
          class User
            def validate_user
              Services::UserService.new.validate(self)
            end
          end
        end
      end

      module Services
        class UserService
          def validate(user)
            App::Models::User.find(user.id)
          end
        end
      end
    RUBY

    expected = {
      "App::Models::User" => [{"Services::UserService" => ["new"]}],
      "Services::UserService" => [{"App::Models::User" => ["find"]}]
    }

    result = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
    assert_equal expected, result
  end

  def test_parses_mixed_nested_and_flat_classes
    ruby_code = <<~RUBY
      class User
        def validate
          App::Models::Profile.create
        end
      end

      module App
        module Models
          class Profile
            def initialize
              User.new
            end
          end
        end
      end
    RUBY

    expected = {
      "User" => [{"App::Models::Profile" => ["create"]}],
      "App::Models::Profile" => [{"User" => ["new"]}]
    }

    result = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
    assert_equal expected, result
  end

  def test_parses_deeply_nested_namespaces
    ruby_code = <<~RUBY
      module App
        module Services
          module External
            class ApiClient
              def call
                App::Models::User.find(1)
              end
            end
          end
        end
      end
    RUBY

    expected = {
      "App::Services::External::ApiClient" => [{"App::Models::User" => ["find"]}]
    }

    result = RailsDependencyExplorer::Parsing::DependencyParser.new(ruby_code).parse
    assert_equal expected, result
  end
end
