module Micdrop
  class MigrateContext
    def initialize(source, sink, loop_item)
      @source = source
      @sink = sink
      @loop_item = loop_item
      @collector = sink.make_collector
    end

    def take(name, put:nil, convert:nil, &block)
      value = @loop_item[name]
      process_item_helper(value, put, convert, block)
    end

    def put(name, value)
      @collector[name] = value
    end

    def collect_list(*items, put:nil, convert:nil, &block)
      value = items.map { |item| item.value }
      process_item_helper(value, put, convert, block)
    end

    def flush()
      @sink.push(@collector)
    end

    private

    def process_item_helper(value, put, convert, block)
      ctx = ItemContext.new(self, value)
      if convert != nil
        ctx.update ctx.instance_eval(&convert)
      end
      if block != nil
        ctx.update ctx.instance_eval(&block)
      end
      if put != nil
        @collector[put] = ctx.value
      end
      ctx
    end
  end
end