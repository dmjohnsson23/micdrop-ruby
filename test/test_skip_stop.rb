# frozen_string_literal: true

require_relative "test_helper"

class TestSkipStop < Minitest::Test
  def setup
    @source = [
      { a: 1 }, { a: 2 }, { a: 3 }, { a: 4 }, { a: 5 },
      { a: 6 }, { a: 7 }, { a: 8 }, { a: 9 }, { a: 10 }
    ]

    @sink = []
  end

  def test_stop_from_top
    Micdrop.migrate @source, @sink do
      a = take(:a)
      stop if a.value == 6

      a.put :a
    end

    assert_equal [
      { a: 1 }, { a: 2 }, { a: 3 }, { a: 4 }, { a: 5 }
    ], @sink
  end

  def test_skip_from_top
    Micdrop.migrate @source, @sink do
      a = take(:a)
      skip if a.value == 1
      skip if a.value == 3
      skip if a.value == 6
      skip if a.value == 9

      a.put :a
    end

    assert_equal [
      { a: 2 }, { a: 4 }, { a: 5 },
      { a: 7 }, { a: 8 }, { a: 10 }
    ], @sink
  end

  def test_stop_from_take_block
    Micdrop.migrate @source, @sink do
      take :a do
        stop if value == 6

        put :a
      end
    end

    assert_equal [
      { a: 1 }, { a: 2 }, { a: 3 }, { a: 4 }, { a: 5 }
    ], @sink
  end

  def test_skip_from_take_block
    Micdrop.migrate @source, @sink do
      take :a do
        skip if value == 1
        skip if value == 3
        skip if value == 6
        skip if value == 9

        put :a
      end
    end

    assert_equal [
      { a: 2 }, { a: 4 }, { a: 5 },
      { a: 7 }, { a: 8 }, { a: 10 }
    ], @sink
  end

  def test_stop_from_apply
    Micdrop.migrate @source, @sink do
      a = take :a
      pipeline = proc do
        stop if value == 6
      end
      a.apply(pipeline)
      a.put :a
    end

    assert_equal [
      { a: 1 }, { a: 2 }, { a: 3 }, { a: 4 }, { a: 5 }
    ], @sink
  end

  def test_skip_from_apply
    Micdrop.migrate @source, @sink do
      a = take :a
      pipeline = proc do
        skip if value == 1
        skip if value == 3
        skip if value == 6
        skip if value == 9
      end
      a.apply(pipeline)
      a.put :a
    end

    assert_equal [
      { a: 2 }, { a: 4 }, { a: 5 },
      { a: 7 }, { a: 8 }, { a: 10 }
    ], @sink
  end
end
