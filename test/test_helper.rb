# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails_dependency_explorer"

require "minitest/autorun"
require_relative "support/file_test_helpers"

# Include shared test helpers in all test classes
class Minitest::Test
  include FileTestHelpers
end
