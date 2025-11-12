# frozen_string_literal: true

# Represets
module Micdrop
  class RecordContext
    def initialize(source, sink, loop_item, loop_index = nil)
      @source = source
      @sink = sink
      @loop_item = loop_item
      @loop_index = loop_index
      reset
    end

    def take(name, put: nil, convert: nil, apply: nil, &block)
      value = @loop_item[name]
      process_item_helper(value, put, convert, apply, block)
    end

    def static(value, put: nil, convert: nil, apply: nil, &block)
      process_item_helper(value, put, convert, apply, block)
    end

    def index(put: nil, convert: nil, apply: nil, &block)
      process_item_helper(@loop_index, put, convert, apply, block)
    end

    def put(name, value)
      @collector[name] = value
      @dirty = true
    end

    def collect_list(*items, put: nil, convert: nil, apply: nil, &block)
      value = items.map(&:value)
      process_item_helper(value, put, convert, apply, block)
    end

    # TODO: collect_hash (not sure what the signature of it should be?)

    def flush(reset: true)
      return unless @dirty

      @sink << @collector
      self.reset if reset
    end

    def reset
      @dirty = false
      @collector = if @sink.respond_to? :make_collector
                     @sink.make_collector
                   else
                     {}
                   end
    end

    private

    def process_item_helper(value, put, convert, apply, block)
      ctx = ItemContext.new(self, value)
      ctx.convert(convert) unless convert.nil?
      ctx.apply(apply) unless apply.nil?
      ctx.apply(block) unless block.nil?
      self.put(put, ctx.value) unless put.nil?
      ctx
    end
  end
end
