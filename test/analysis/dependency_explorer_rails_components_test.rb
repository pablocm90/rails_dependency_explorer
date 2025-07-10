# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyExplorerRailsComponentsTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_dependency_explorer_identifies_rails_components
    ruby_code = create_rails_components_code
    result = @explorer.analyze_code(ruby_code)
    
    # Should categorize dependencies by Rails component type
    components = result.rails_components
    
    # Should identify models
    assert_includes components[:models], "User"
    assert_includes components[:models], "Post"
    
    # Should identify controllers
    assert_includes components[:controllers], "UsersController"
    assert_includes components[:controllers], "PostsController"
    
    # Should identify services
    assert_includes components[:services], "UserService"
    assert_includes components[:services], "EmailService"
    
    # Should identify other/unknown components
    assert_includes components[:other], "Logger"
    assert_includes components[:other], "Redis"
  end

  private

  def create_rails_components_code
    <<~RUBY
      class User < ApplicationRecord
        has_many :posts
        validates :email, presence: true
      end

      class Post < ApplicationRecord
        belongs_to :user
      end

      class UsersController < ApplicationController
        def index
          @users = User.all
          UserService.new.send_welcome_email
        end
      end

      class PostsController < ApplicationController
        def create
          @post = Post.new(post_params)
          Logger.info("Creating post")
        end
      end

      class UserService
        def initialize
          @email_service = EmailService.new
          @redis = Redis.new
        end
      end

      class EmailService
        def send_welcome_email
          # Send email logic
        end
      end
    RUBY
  end
end
