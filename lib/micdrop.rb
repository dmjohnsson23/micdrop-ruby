# frozen_string_literal: true

require_relative "micdrop/array_sink"
require_relative "micdrop/item_context"
require_relative "micdrop/record_context"
require_relative "micdrop/version"

module Micdrop
  def self.migrate(from, to, &block)
    if from.respond_to? :each_with_index
      from.each_with_index do |loop_item, loop_index|
        migrate_item_helper(from, to, loop_item, loop_index, &block)
      end
    elsif from.respond_to? :each_pair
      from.each_pair do |loop_index, loop_item|
        migrate_item_helper(from, to, loop_item, loop_index, &block)
      end
    elsif from.respond_to? :each
      from.each.with_index do |loop_item, loop_index|
        migrate_item_helper(from, to, loop_item, loop_index, &block)
      end
    else
      # TODO: error
    end
  end

  def self.migrate_item_helper(from, to, loop_item, loop_index, &block)
    ctx = RecordContext.new(from, to, loop_item, loop_index)
    ctx.instance_eval(&block)
    ctx.flush reset: false # No need to reset; item processing is done
  end
end
