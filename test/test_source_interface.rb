# frozen_string_literal: true

require_relative "test_helper"

module IsSource
  def self.included(_base) # rubocop:disable Metrics/MethodLength
    describe "Source" do
      it "responds to each" do
        _(@object).must_respond_to :each
      end
      it "yields items that respond to []" do
        @object.each do |item| # rubocop:disable Lint/UnreachableLoop
          _(item).must_respond_to :[]
          break
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
