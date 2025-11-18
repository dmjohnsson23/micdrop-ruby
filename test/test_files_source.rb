# frozen_string_literal: true

require_relative "test_helper"
require_relative "test_source_interface"

describe Micdrop::FilesSource do
  describe "is a source" do
    include IsSource
    before do
      @object = Micdrop::FilesSource.new(Dir.getwd)
    end
  end

  it "can iterate a preset list of files" do
    source = Micdrop::FilesSource.new(File.join(__dir__, "../examples/data/json"), files: ["a.json", "1.json"])
    files = source.each_pair.to_a

    _(files.count).must_equal 2
  end

  it "can iterate all files in a directory" do
    source = Micdrop::FilesSource.new(File.join(__dir__, "../examples/data/json"))
    files = source.each_pair.to_a

    _(files.count).must_equal 10
  end

  it "can iterate a glob" do
    source = Micdrop::FilesSource.new(File.join(__dir__, "../examples/data/json"), glob: "[0-9].json")
    files = source.each_pair.to_a

    _(files.count).must_equal 9
  end
end

describe Micdrop::FilesSourceRecord do
  before do
    @record = Micdrop::FilesSourceRecord.new File.join(__dir__, "../examples/data/json/a.json"), {}
  end

  it "can read a file" do
    _(@record[:content]).must_equal '{"name": "Lauren Velasquez", "residency": "566 Cameron Ranch Suite 297\\nWest Kimberly, IA 07395"}'
  end

  it "knows the path" do
    _(@record[:filename]).must_equal File.join(__dir__, "../examples/data/json/a.json")
    _(@record[:basename]).must_equal "a.json"
    _(@record[:path]).must_equal File.absolute_path("../examples/data/json/a.json", __dir__)
  end

  it "can get stats" do
    _(@record[:size]).must_equal 97
    _(@record[:zero?]).must_equal false
  end
end
