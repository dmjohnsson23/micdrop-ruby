# frozen_string_literal: true

require_relative "test_helper"

class TestMicdrop < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Micdrop::VERSION
  end
end
