# frozen_string_literal: true

require 'minitest/autorun'

class DependencyParserTest < Minitest::Test
  def test
    ruby_code = <<~RUBY
     class Player
        def attack(enemy: Enemy)
          enemy.health -= 10
        end
      end
    RUBY
    expected = {
      "Player" => [{
                     "Enemy": ['health']
                   }]
    }
    assert_equal expected, DependencyParser.parse(ruby_code)
  end
end
