# frozen_string_literal: true

require_relative "test_helper"

describe Micdrop::ItemContext do # rubocop:disable Metrics/BlockLength
  describe :convert do
    before do
      @ctx = Micdrop::ItemContext.new(nil, 10)
    end

    it "can be run with a symbol"
    it "can be run with a proc" do
      @ctx.convert(proc { it * 2 })

      _(@ctx.value).must_equal 20
    end
    it "can be run with a block" do
      @ctx.convert { it * 2 }

      _(@ctx.value).must_equal 20
    end
  end

  describe :apply do
    before do
      @ctx = Micdrop::ItemContext.new(nil, "10")
    end

    it "can be run with a symbol referencing an ItemContext method" do
      @ctx.apply :parse_int

      _(@ctx.value).must_equal 10
    end
    it "can be run with a symbol referencing an externally defined method"
    it "can be run with a proc" do
      @ctx.apply(proc { parse_int })

      _(@ctx.value).must_equal 10
    end
  end

  describe :parse_date do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.parse_date

      _(ctx.value).must_be_nil
    end
    it "handles zero dates" do
      ctx = Micdrop::ItemContext.new(nil, "0000-00-00")
      ctx.parse_date zero_date: true

      _(ctx.value).must_be_nil
    end
    it "parses a date in ISO format" do
      ctx = Micdrop::ItemContext.new(nil, "2021-09-01")
      ctx.parse_date

      _(ctx.value).must_equal Date.new(2021, 9, 1)
    end
    it "parses a date in a custom format" do
      ctx = Micdrop::ItemContext.new(nil, "09/01/21")
      ctx.parse_date "%m/%d/%y"

      _(ctx.value).must_equal Date.new(2021, 9, 1)
    end
  end

  describe :parse_datetime do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.parse_datetime

      _(ctx.value).must_be_nil
    end
    it "handles zero datetimes" do
      ctx = Micdrop::ItemContext.new(nil, "0000-00-00 00:00:00")
      ctx.parse_datetime zero_date: true

      _(ctx.value).must_be_nil
    end
    it "parses a datetime in ISO format" do
      ctx = Micdrop::ItemContext.new(nil, "2021-09-01 14:53:00")
      ctx.parse_datetime

      _(ctx.value).must_equal DateTime.new(2021, 9, 1, 14, 53, 0)
    end
    it "parses a datetime in a custom format" do
      ctx = Micdrop::ItemContext.new(nil, "09/01/21 2:53 PM")
      ctx.parse_datetime "%m/%d/%y %k:%M %p"

      _(ctx.value).must_equal DateTime.new(2021, 9, 1, 14, 53, 0)
    end
  end

  describe :format_date do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_date

      _(ctx.value).must_be_nil
    end
    it "can generate zero dates" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_date zero_date: true

      _(ctx.value).must_equal "0000-00-00"
    end
    it "formats a date" do
      ctx = Micdrop::ItemContext.new(nil, Date.new(2024, 11, 14))
      ctx.format_date

      _(ctx.value).must_equal "2024-11-14"
    end
  end

  describe :format_datetime do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_datetime

      _(ctx.value).must_be_nil
    end
    it "can generate zero datetimes" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_datetime zero_date: true

      _(ctx.value).must_equal "0000-00-00 00:00:00"
    end
    it "formats a datetime" do
      ctx = Micdrop::ItemContext.new(nil, DateTime.new(2024, 11, 14, 4, 55))
      ctx.format_datetime

      _(ctx.value).must_equal "2024-11-14 04:55:00"
    end
  end

  describe :parse_boolean do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.parse_boolean

      _(ctx.value).must_be_nil
    end
    it "allows several values" do
      ctx_true1 = Micdrop::ItemContext.new(nil, "true")
      ctx_true2 = Micdrop::ItemContext.new(nil, "Yes")
      ctx_false1 = Micdrop::ItemContext.new(nil, "false")
      ctx_false2 = Micdrop::ItemContext.new(nil, "No")
      ctx_false3 = Micdrop::ItemContext.new(nil, "")

      ctx_true1.parse_boolean
      ctx_true2.parse_boolean
      ctx_false1.parse_boolean
      ctx_false2.parse_boolean
      ctx_false3.parse_boolean

      _(ctx_true1.value).must_equal true
      _(ctx_true2.value).must_equal true
      _(ctx_false1.value).must_equal false
      _(ctx_false2.value).must_equal false
      _(ctx_false3.value).must_equal false
    end
    it "accepts custom values" do
      ctx_true = Micdrop::ItemContext.new(nil, "Darn Right!")
      ctx_false = Micdrop::ItemContext.new(nil, "Ain't No Way!")

      ctx_true.parse_boolean ["Darn Right!"], ["Ain't No Way!"]
      ctx_false.parse_boolean ["Darn Right!"], ["Ain't No Way!"]

      _(ctx_true.value).must_equal true
      _(ctx_false.value).must_equal false
    end
    it "errors on an unmatched value"
  end

  describe :format_boolean do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_boolean

      _(ctx.value).must_be_nil
    end
    it "formats a boolean" do
      ctx_true = Micdrop::ItemContext.new(nil, true)
      ctx_false = Micdrop::ItemContext.new(nil, false)

      ctx_true.format_boolean
      ctx_false.format_boolean

      _(ctx_true.value).must_equal "Yes"
      _(ctx_false.value).must_equal "No"
    end
    it "accepts custom values" do
      ctx_true = Micdrop::ItemContext.new(nil, true)
      ctx_false = Micdrop::ItemContext.new(nil, false)

      ctx_true.format_boolean "Darn Right!", "Ain't No Way!"
      ctx_false.format_boolean "Darn Right!", "Ain't No Way!"

      _(ctx_true.value).must_equal "Darn Right!"
      _(ctx_false.value).must_equal "Ain't No Way!"
    end
  end

  describe :format_string do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.format_string "%s"

      _(ctx.value).must_be_nil
    end

    it "formats a string" do
      ctx = Micdrop::ItemContext.new(nil, 1)
      ctx.format_string "%s"

      _(ctx.value).must_equal "1"
    end
  end

  describe :lookup do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.lookup({ "A" => 1, "B" => 2 })

      _(ctx.value).must_be_nil
    end

    it "converts a known value" do
      ctx = Micdrop::ItemContext.new(nil, "A")
      ctx.lookup({ "A" => 1, "B" => 2 })

      _(ctx.value).must_equal 1
    end

    it "optionally passes the original value on an unknown value" do
      ctx = Micdrop::ItemContext.new(nil, "C")
      ctx.lookup({ "A" => 1, "B" => 2 }, pass_if_not_found: true)

      _(ctx.value).must_equal "C"
    end

    it "behaves appropriately when passed an unknown value"
  end

  describe :string_replace do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.string_replace "a", "b"

      _(ctx.value).must_be_nil
    end
    it "replaces all matching values in a string" do
      ctx = Micdrop::ItemContext.new(nil, "bananas")
      ctx.string_replace "a", "i"

      _(ctx.value).must_equal "bininis"
    end

    it "works with regex"
  end

  describe :extract do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.extract 2

      _(ctx.value).must_be_nil
    end
    it "extracts a single item from an array" do
      ctx = Micdrop::ItemContext.new(nil, [1, 2, 3, 4, 5, 6, 7, 8, 9])
      ctx.extract 2

      _(ctx.value).must_equal 3
    end
    it "slices an array with a range" do
      ctx = Micdrop::ItemContext.new(nil, [1, 2, 3, 4, 5, 6, 7, 8, 9])
      ctx.extract 2..4

      _(ctx.value).must_equal [3, 4, 5]
    end
  end

  describe :default do
    it "overwrites nil" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.default 10
      _(ctx.value).must_equal 10
    end
    it "doesn't overwrite actual values" do
      ctx = Micdrop::ItemContext.new(nil, 5)
      ctx.default 10
      _(ctx.value).must_equal 5
    end
  end

  describe :split do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.split ","

      _(ctx.value).must_be_nil
    end
    it "splits a string"
  end

  describe :join do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.join ","

      _(ctx.value).must_be_nil
    end
    it "joins an array"
  end

  describe :split_kv do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.split_kv ": "

      _(ctx.value).must_be_nil
    end
    it "splits a known good string on into key/value pairs"
    it "throws an error on a bad string"
  end

  describe :join_kv do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      ctx.join_kv ": "

      _(ctx.value).must_be_nil
    end
    it "joins a hash"
  end
end
