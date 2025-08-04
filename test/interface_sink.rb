require_relative "test_helper"

module IsSink
  def self.included(base)
    describe "Sink" do
      it "responds to push" do
        _(@object).must_respond_to :push
      end
      it "responds to make_collector" do
        _(@object).must_respond_to :make_collector
      end
      it "make_collector returns an item that responds to []=" do
        _(@object.make_collector).must_respond_to :[]=
      end
      it "push accepts a value returned by make_collector" do
        @object.push @object.make_collector
      end
    end
  end
end


describe "ArraySink" do
  include IsSink

  before do
    @object = Micdrop::ArraySink.new
  end
end