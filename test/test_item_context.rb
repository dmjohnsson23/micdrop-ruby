# frozen_string_literal: true

require_relative "test_helper"

def some_random_method(value)
  value * 2
end

describe Micdrop::ItemContext do # rubocop:disable Metrics/BlockLength
  describe :value do
    before do
      @ctx = Micdrop::ItemContext.new(nil, 10)
    end

    it "is readable" do
      _(@ctx.value).must_equal 10
    end
    it "is settable" do
      @ctx.value = 20
      _(@ctx.value).must_equal 20
    end
    it "can be updated via update" do
      _(@ctx.update(20)).must_be_same_as @ctx
      _(@ctx.value).must_equal 20
    end
  end
  describe :convert do
    before do
      @ctx = Micdrop::ItemContext.new(nil, 10)
    end

    it "can be run with a symbol" do
      _(@ctx.convert(:some_random_method)).must_be_same_as @ctx

      _(@ctx.value).must_equal 20
    end
    it "can be run with a proc" do
      _(@ctx.convert(proc { it * 2 })).must_be_same_as @ctx

      _(@ctx.value).must_equal 20
    end
    it "can be run with a block" do
      _(@ctx.convert { it * 2 }).must_be_same_as @ctx

      _(@ctx.value).must_equal 20
    end
  end

  describe :apply do
    before do
      @ctx = Micdrop::ItemContext.new(nil, "10")
    end

    it "can be run with a symbol referencing an ItemContext method" do
      _(@ctx.apply(:parse_int)).must_be_same_as @ctx

      _(@ctx.value).must_equal 10
    end
    it "can be run with a symbol referencing an externally defined method"
    it "can be run with a proc" do
      _(@ctx.apply(proc { parse_int })).must_be_same_as @ctx

      _(@ctx.value).must_equal 10
    end
  end

  describe :scope do
    before do
      @ctx = Micdrop::ItemContext.new(nil, 10)
    end

    it "contains updates to an independent scope" do
      scoped = @ctx.scope
      _(@ctx.update(9)).must_be_same_as @ctx
      _(scoped.update(11)).must_be_same_as scoped

      _(@ctx.value).must_equal 9
      _(scoped.value).must_equal 11
    end

    it "returns a new ItemContext" do
      scoped = @ctx.scope

      _(scoped).must_be_instance_of Micdrop::ItemContext
      _(scoped).wont_be_same_as @ctx
    end
  end

  describe :extract do
    before do
      @ctx = Micdrop::ItemContext.new(nil, { a: 10, b: 15 })
    end

    it "extracts child values" do
      @ctx.extract :a

      _(@ctx.value).must_equal 10
    end

    it "plays well with scope" do
      a = @ctx.scope.extract :a
      b = @ctx.scope.extract :b

      _(a.value).must_equal 10
      _(b.value).must_equal 15
    end
  end

  describe :parse_date do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.parse_date).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "handles zero dates" do
      ctx = Micdrop::ItemContext.new(nil, "0000-00-00")
      _(ctx.parse_date(zero_date: true)).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "parses a date in ISO format" do
      ctx = Micdrop::ItemContext.new(nil, "2021-09-01")
      _(ctx.parse_date).must_be_same_as ctx

      _(ctx.value).must_equal Date.new(2021, 9, 1)
    end
    it "parses a date in a custom format" do
      ctx = Micdrop::ItemContext.new(nil, "09/01/21")
      _(ctx.parse_date("%m/%d/%y")).must_be_same_as ctx

      _(ctx.value).must_equal Date.new(2021, 9, 1)
    end
  end

  describe :parse_datetime do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.parse_datetime).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "handles zero datetimes" do
      ctx = Micdrop::ItemContext.new(nil, "0000-00-00 00:00:00")
      _(ctx.parse_datetime(zero_date: true)).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "parses a datetime in ISO format" do
      ctx = Micdrop::ItemContext.new(nil, "2021-09-01 14:53:00")
      _(ctx.parse_datetime).must_be_same_as ctx

      _(ctx.value).must_equal DateTime.new(2021, 9, 1, 14, 53, 0)
    end
    it "parses a datetime in a custom format" do
      ctx = Micdrop::ItemContext.new(nil, "09/01/21 2:53 PM")
      _(ctx.parse_datetime("%m/%d/%y %k:%M %p")).must_be_same_as ctx

      _(ctx.value).must_equal DateTime.new(2021, 9, 1, 14, 53, 0)
    end
  end

  describe :format_date do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_date).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "can generate zero dates" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_date(zero_date: true)).must_be_same_as ctx

      _(ctx.value).must_equal "0000-00-00"
    end
    it "formats a date" do
      ctx = Micdrop::ItemContext.new(nil, Date.new(2024, 11, 14))
      _(ctx.format_date).must_be_same_as ctx

      _(ctx.value).must_equal "2024-11-14"
    end
  end

  describe :format_datetime do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_datetime).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "can generate zero datetimes" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_datetime(zero_date: true)).must_be_same_as ctx

      _(ctx.value).must_equal "0000-00-00 00:00:00"
    end
    it "formats a datetime" do
      ctx = Micdrop::ItemContext.new(nil, DateTime.new(2024, 11, 14, 4, 55))
      _(ctx.format_datetime).must_be_same_as ctx

      _(ctx.value).must_equal "2024-11-14 04:55:00"
    end
  end

  describe :parse_boolean do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.parse_boolean).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "allows several values" do
      ctx_true1 = Micdrop::ItemContext.new(nil, "true")
      ctx_true2 = Micdrop::ItemContext.new(nil, "Yes")
      ctx_false1 = Micdrop::ItemContext.new(nil, "false")
      ctx_false2 = Micdrop::ItemContext.new(nil, "No")
      ctx_false3 = Micdrop::ItemContext.new(nil, "")

      _(ctx_true1.parse_boolean).must_be_same_as ctx_true1
      _(ctx_true2.parse_boolean).must_be_same_as ctx_true2
      _(ctx_false1.parse_boolean).must_be_same_as ctx_false1
      _(ctx_false2.parse_boolean).must_be_same_as ctx_false2
      _(ctx_false3.parse_boolean).must_be_same_as ctx_false3

      _(ctx_true1.value).must_equal true
      _(ctx_true2.value).must_equal true
      _(ctx_false1.value).must_equal false
      _(ctx_false2.value).must_equal false
      _(ctx_false3.value).must_equal false
    end
    it "accepts custom values" do
      ctx_true = Micdrop::ItemContext.new(nil, "Darn Right!")
      ctx_false = Micdrop::ItemContext.new(nil, "Ain't No Way!")

      _(ctx_true.parse_boolean(["Darn Right!"], ["Ain't No Way!"])).must_be_same_as ctx_true
      _(ctx_false.parse_boolean(["Darn Right!"], ["Ain't No Way!"])).must_be_same_as ctx_false

      _(ctx_true.value).must_equal true
      _(ctx_false.value).must_equal false
    end
    it "errors on an unmatched value"
  end

  describe :format_boolean do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_boolean).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "formats a boolean" do
      ctx_true = Micdrop::ItemContext.new(nil, true)
      ctx_false = Micdrop::ItemContext.new(nil, false)

      _(ctx_true.format_boolean).must_be_same_as ctx_true
      _(ctx_false.format_boolean).must_be_same_as ctx_false

      _(ctx_true.value).must_equal "Yes"
      _(ctx_false.value).must_equal "No"
    end
    it "accepts custom values" do
      ctx_true = Micdrop::ItemContext.new(nil, true)
      ctx_false = Micdrop::ItemContext.new(nil, false)

      _(ctx_true.format_boolean("Darn Right!", "Ain't No Way!")).must_be_same_as ctx_true
      _(ctx_false.format_boolean("Darn Right!", "Ain't No Way!")).must_be_same_as ctx_false

      _(ctx_true.value).must_equal "Darn Right!"
      _(ctx_false.value).must_equal "Ain't No Way!"
    end
  end

  describe :format_string do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.format_string("%s")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end

    it "formats a string" do
      ctx = Micdrop::ItemContext.new(nil, 1)
      _(ctx.format_string("%s")).must_be_same_as ctx

      _(ctx.value).must_equal "1"
    end
  end

  describe :lookup do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.lookup({ "A" => 1, "B" => 2 })).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end

    it "converts a known value" do
      ctx = Micdrop::ItemContext.new(nil, "A")
      _(ctx.lookup({ "A" => 1, "B" => 2 })).must_be_same_as ctx

      _(ctx.value).must_equal 1
    end

    it "optionally passes the original value on an unknown value" do
      ctx = Micdrop::ItemContext.new(nil, "C")
      _(ctx.lookup({ "A" => 1, "B" => 2 }, pass_if_not_found: true)).must_be_same_as ctx

      _(ctx.value).must_equal "C"
    end

    it "behaves appropriately when passed an unknown value"
  end

  describe :string_replace do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.string_replace("a", "b")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "replaces all matching values in a string" do
      ctx = Micdrop::ItemContext.new(nil, "bananas")
      _(ctx.string_replace("a", "i")).must_be_same_as ctx

      _(ctx.value).must_equal "bininis"
    end

    it "works with regex"
  end

  describe :extract do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.extract(2)).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "extracts a single item from an array" do
      ctx = Micdrop::ItemContext.new(nil, [1, 2, 3, 4, 5, 6, 7, 8, 9])
      _(ctx.extract(2)).must_be_same_as ctx

      _(ctx.value).must_equal 3
    end
    it "slices an array with a range" do
      ctx = Micdrop::ItemContext.new(nil, [1, 2, 3, 4, 5, 6, 7, 8, 9])
      _(ctx.extract(2..4)).must_be_same_as ctx

      _(ctx.value).must_equal [3, 4, 5]
    end
  end

  describe :default do
    it "overwrites nil" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.default(10)).must_be_same_as ctx
      _(ctx.value).must_equal 10
    end
    it "doesn't overwrite actual values" do
      ctx = Micdrop::ItemContext.new(nil, 5)
      _(ctx.default(10)).must_be_same_as ctx
      _(ctx.value).must_equal 5
    end
  end

  describe :split do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.split(",")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "splits a string"
  end

  describe :join do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.join(",")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "joins an array"
  end

  describe :split_kv do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.split_kv(": ")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "splits a known good string on into key/value pairs"
    it "throws an error on a bad string"
  end

  describe :join_kv do
    it "handles nil gracefully" do
      ctx = Micdrop::ItemContext.new(nil, nil)
      _(ctx.join_kv(": ")).must_be_same_as ctx

      _(ctx.value).must_be_nil
    end
    it "joins a hash" do
      ctx = Micdrop::ItemContext.new(nil, { "A" => "1", "B" => "2" })
      _(ctx.join_kv(": ")).must_be_same_as ctx

      _(ctx.value).must_equal "A: 1\nB: 2"
    end
  end
end
