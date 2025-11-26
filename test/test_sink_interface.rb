# frozen_string_literal: true

require_relative "test_helper"

module IsSink
  def self.included(_base) # rubocop:disable Metrics/MethodLength
    describe "Sink" do
      it "responds to <<" do
        _(@object).must_respond_to :<<
      end

      if @object.respond_to? :make_collector
        it "make_collector returns an item that responds to []=" do
          _(@object.make_collector).must_respond_to :[]=
        end
        it "<< accepts a value returned by make_collector" do
          @object << @object.make_collector
        end
      else
        it "<< accepts a hash" do
          @object << {}
        end
      end
    end
  end
end

describe "ArraySink" do
  include IsSink

  before do
    @object = []
  end
end
