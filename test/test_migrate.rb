# frozen_string_literal: true

require_relative "test_helper"

class TestMicdrop < Minitest::Test
  def setup
    @source = [
      { a: 1, b: 2 },
      { a: 3, b: 4 },
      { a: 5, b: 6 }
    ]

    @sink = []
  end

  def test_simple_take_and_put
    Micdrop.migrate @source, @sink do
      take :a, put: "A"
      take :b, put: "B"
    end

    assert_equal [
      { "A" => 1, "B" => 2 },
      { "A" => 3, "B" => 4 },
      { "A" => 5, "B" => 6 }
    ], @sink
  end

  def test_using_blocks # rubocop:disable Metrics/MethodLength
    Micdrop.migrate @source, @sink do
      take :a do
        update value + 1
        put "A"
      end
      take :b do
        convert { it * 2 }
        put "B"
      end
    end

    assert_equal [
      { "A" => 2, "B" => 4 },
      { "A" => 4, "B" => 8 },
      { "A" => 6, "B" => 12 }
    ], @sink
  end

  def test_using_apply_procs # rubocop:disable Metrics/MethodLength
    plusser = proc {
      update value + 1
    }
    timeser = proc {
      convert { |v| v * 2 }
    }

    Micdrop.migrate @source, @sink do
      take :a, apply: plusser, put: "A"
      take :b, apply: timeser, put: "B"
    end

    assert_equal [
      { "A" => 2, "B" => 4 },
      { "A" => 4, "B" => 8 },
      { "A" => 6, "B" => 12 }
    ], @sink
  end

  def test_using_convert_procs
    Micdrop.migrate @source, @sink do
      take :a, convert: ->(v) { v + 1 }, put: "A"
      take :b, convert: ->(v) { v * 2 }, put: "B"
    end

    assert_equal [
      { "A" => 2, "B" => 4 },
      { "A" => 4, "B" => 8 },
      { "A" => 6, "B" => 12 }
    ], @sink
  end
end
