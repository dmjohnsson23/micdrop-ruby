# frozen_string_literal: true

require_relative "test_helper"
require_relative "test_source_interface"
require_relative "test_sink_interface"
require "micdrop/ext/json_lines"


describe "Micdrop::Ext::JsonLines" do # rubocop:disable Metrics/BlockLength
  describe "JsonLinesSource" do
    describe "is a source" do
        include IsSource
        before do
        file = Tempfile.create 
        @object = Micdrop::Ext::JsonLines::JsonLinesSource.new(file)
        end
    end
    it "parses json lines" do
      file = Tempfile.create 
      file.write("{\"a\":1}\n{\"a\":2}")
      file.rewind
      source = Micdrop::Ext::JsonLines::JsonLinesSource.new(file)
      records = source.each.to_a

      _(records.count).must_equal 2
      _(records[0]["a"]).must_equal 1
      _(records[1]["a"]).must_equal 2
    end
  end

  describe "JsonLinesSink" do
    describe "is a sink" do
        include IsSink
        before do
        file = Tempfile.create 
        @object = Micdrop::Ext::JsonLines::JsonLinesSink.new(file)
        end
    end
    it "parses json lines" do
      file = Tempfile.create 
      sink = Micdrop::Ext::JsonLines::JsonLinesSink.new(file)
      
      sink << ({a:1})
      sink << ({a:2})

      file.rewind
      _(file.read).must_equal "{\"a\":1}\n{\"a\":2}\n"
    end
  end
end
