# frozen_string_literal: true

require_relative "test_helper"

class TestMicdrop < Minitest::Test
  def test_that_it_can_take_and_put_values
    source = [
      {a:1, b:2},
      {a:3, b:4},
      {a:5, b:6},
    ]

    sink = Micdrop::ArraySink.new()

    Micdrop.migrate source, sink do
      take :a, put: 'A'
      take :b, put: 'B'
    end

    assert_equal [
      {'A'=>1, 'B'=>2},
      {'A'=>3, 'B'=>4},
      {'A'=>5, 'B'=>6},
    ], sink
  end
end
