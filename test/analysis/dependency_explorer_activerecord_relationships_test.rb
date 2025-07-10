# frozen_string_literal: true

require "minitest/autorun"
require_relative "../test_helper"

class DependencyExplorerActiveRecordRelationshipsTest < Minitest::Test
  def setup
    @explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
  end

  def test_dependency_explorer_analyzes_activerecord_relationships
    ruby_code = create_activerecord_models_code
    result = @explorer.analyze_code(ruby_code)

    # Should detect ActiveRecord relationships
    relationships = result.activerecord_relationships

    # Should identify belongs_to relationships
    user_relationships = relationships["User"]
    assert_includes user_relationships[:belongs_to], "Account"

    # Should identify has_many relationships
    assert_includes user_relationships[:has_many], "Post"
    assert_includes user_relationships[:has_many], "Comment"

    # Should identify has_one relationships
    assert_includes user_relationships[:has_one], "Profile"

    # Should identify has_and_belongs_to_many relationships
    assert_includes user_relationships[:has_and_belongs_to_many], "Role"

    # Should identify relationships in other models
    post_relationships = relationships["Post"]
    assert_includes post_relationships[:belongs_to], "User"
    assert_includes post_relationships[:has_many], "Comment"

    # Should handle models without relationships
    comment_relationships = relationships["Comment"]
    assert_includes comment_relationships[:belongs_to], "User"
    assert_includes comment_relationships[:belongs_to], "Post"
  end

  private

  def create_activerecord_models_code
    <<~RUBY
      class User < ApplicationRecord
        belongs_to :account
        has_many :posts
        has_many :comments
        has_one :profile
        has_and_belongs_to_many :roles
        
        validates :email, presence: true
      end

      class Post < ApplicationRecord
        belongs_to :user
        has_many :comments
        
        scope :published, -> { where(published: true) }
      end

      class Comment < ApplicationRecord
        belongs_to :user
        belongs_to :post
        
        validates :content, presence: true
      end

      class Profile < ApplicationRecord
        belongs_to :user
      end

      class Account < ApplicationRecord
        has_many :users
      end

      class Role < ApplicationRecord
        has_and_belongs_to_many :users
      end
    RUBY
  end
end
