# frozen_string_literal: true

require_relative "test_helper"

module IsSource
  def self.included(_base) # rubocop:disable Metrics/MethodLength
    describe "Source" do
      it "responds to each" do
        assert(@object.respond_to?(:each) || @object.respond_to?(:each_pair) || @object.respond_to?(:each_with_index),
               "All sources must respond to :each, :each_pair, and/or :each_with_index")
      end
      if @object.respond_to? :each
        describe :each do
          @object.each do |item| # rubocop:disable Lint/UnreachableLoop
            it "yields items that respond to []" do
              _(item).must_respond_to :[]
            end
            break
          end
        end
      end
      if @object.respond_to? :each_pair
        describe :each_pair do
          @object.each_pair do |key, item| # rubocop:disable Lint/UnreachableLoop
            it "yields items that respond to []" do
              _(item).must_respond_to :[]
            end
            break
          end
        end
      end
      if @object.respond_to? :each_with_index
        describe :each_with_index do
          @object.each_with_index do |item, index| # rubocop:disable Lint/UnreachableLoop
            it "yields items that respond to []" do
              _(item).must_respond_to :[]
            end
            break
          end
        end
      end
    end
  end
end

describe "ArraySource" do
  include IsSource

  before do
    @object = [
      { a: 1, b: 2 },
      { a: 3, b: 4 },
      { a: 5, b: 6 }
    ]
  end
end
