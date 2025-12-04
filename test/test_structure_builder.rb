# frozen_string_literal: true

require_relative "test_helper"

describe Micdrop::StructureBuilder do
  describe "basic operations on blank" do
    before do
      @obj = Micdrop::StructureBuilder.new_blank
    end

    it "sets a simple string key" do
      @obj[:simple] = :ok

      _(@obj.raw_value).must_equal({ simple: :ok })
    end

    it "sets a simple array key" do
      @obj[0] = :ok

      _(@obj.raw_value).must_equal([:ok])
    end

    it "sets a blank array key" do
      @obj[] = :ok

      _(@obj.raw_value).must_equal([:ok])
    end

    it "sets multiple simple string keys" do
      @obj[:simple] = :ok
      @obj[:again] = :yep

      _(@obj.raw_value).must_equal({ simple: :ok, again: :yep })
    end

    it "sets multiple simple array keys" do
      @obj[0] = :ok
      @obj[1] = :cool

      _(@obj.raw_value).must_equal(%i[ok cool])
    end

    it "sets multiple blank array keys" do
      @obj[] = :ok
      @obj[] = :cool

      _(@obj.raw_value).must_equal(%i[ok cool])
    end

    it "sets a nested key" do
      @obj[:nested][:key] = :ok

      _(@obj.raw_value).must_equal({ nested: { key: :ok } })
    end

    it "sets a simple string key as an array" do
      @obj[:array][] = 1
      @obj[:array][] = 2

      _(@obj.raw_value).must_equal({ array: [1, 2] })
    end

    it "allows explcit array indices" do
      @obj[:array][2] = "two"
      @obj[:array][0] = "zero"
      @obj[:array][1] = "one"

      _(@obj.raw_value).must_equal({ array: %w[zero one two] })
    end

    it "allows a hash key after an array" do
      @obj[:array][][:item] = :ok

      _(@obj.raw_value).must_equal({ array: [{ item: :ok }] })
    end

    it "can reference a previous array item with a negative key" do
      @obj[:array][][:item] = :ok
      @obj[:array][-1][:coolness] = 5

      _(@obj.raw_value).must_equal({ array: [{ item: :ok, coolness: 5 }] })
    end

    it "creates a second item if there is not a negative index" do
      @obj[:array][][:item] = :ok
      @obj[:array][][:coolness] = 5

      _(@obj.raw_value).must_equal({ array: [{ item: :ok }, { coolness: 5 }] })
    end

    it "supports multiple array pushes chained" do
      @obj[][][] = :first
      @obj[][][] = :second

      _(@obj.raw_value).must_equal([[[:first]], [[:second]]])
    end
  end

  describe :bury do
    before do
      @obj = Micdrop::StructureBuilder.new_blank
    end

    it "sets a simple string key" do
      @obj.bury :ok, :simple

      _(@obj.raw_value).must_equal({ simple: :ok })
    end

    it "sets a simple array key" do
      @obj.bury :ok, 0

      _(@obj.raw_value).must_equal([:ok])
    end

    it "pushes on nil" do
      @obj.bury :ok, nil

      _(@obj.raw_value).must_equal([:ok])
    end

    it "sets a deeply nested key" do
      @obj.bury :ok, :deeply, :nested, :key

      _(@obj.raw_value).must_equal({ deeply: { nested: { key: :ok } } })
    end
  end
end
