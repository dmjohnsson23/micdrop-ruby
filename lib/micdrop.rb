# frozen_string_literal: true

require_relative "micdrop/array_sink"
require_relative "micdrop/item_context"
require_relative "micdrop/migrate_context"
require_relative "micdrop/version"

module Micdrop
  def self.migrate(from, to, &block)
    from.each do |loop_item|
        ctx = MigrateContext.new(from, to, loop_item)
        ctx.instance_eval(&block)
        ctx.flush
    end
  end
end
