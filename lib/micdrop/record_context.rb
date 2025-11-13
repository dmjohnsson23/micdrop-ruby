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

    ##
    # `take` extracts a single item from a record (e.g. a column from a row) and allows it to be
    # operated upon. This is one of the most common operations you will use. It takes the following
    # additional options:
    #
    # * `put` specifies where the taken vaue will go in the sink, after all transformations are
    #   applied.
    # * `convert` takes a proc or function that will be called on the taken value. The new value
    #   will be the return value of the function.
    # * `apply` takes a proc or function that will be used as a pipeline to transform the value.
    #   See `ItemContext` for details. (Passing a block also has the same effect.)
    def take(name, put: nil, convert: nil, apply: nil, &block)
      value = @loop_item[name]
      process_item_helper(value, put, convert, apply, block)
    end

    ##
    # `static` is a variant of `take` that, instead of actually taking data from the source record,
    # allows you to specify your own value. This is usually used to supply values which are not
    # provided in the source, but required in the sink.
    def static(value, put: nil, convert: nil, apply: nil, &block)
      process_item_helper(value, put, convert, apply, block)
    end

    ##
    # `index` is a special form of `take` which takes the record index rather than an actual value
    # from the record. You can use this as a unique identifier if the source does not have an
    # explicit identifier.
    def index(put: nil, convert: nil, apply: nil, &block)
      process_item_helper(@loop_index, put, convert, apply, block)
    end

    ##
    # Put a value in the sink.
    #
    # You typically won't use this directly.
    def put(name, value)
      @collector[name] = value
      @dirty = true
    end

    ##
    # Create a new list record which collections multiple `take`s into a single list.
    #
    # Accepts all the same arguments as `take`. Then taken value will be a list of all constituent
    # taken values. This is often used to join or concatenate items in the source in some way.
    def collect_list(*items, put: nil, convert: nil, apply: nil, &block)
      value = items.map(&:value)
      process_item_helper(value, put, convert, apply, block)
    end

    # TODO: collect_hash (not sure what the signature of it should be?)

    ##
    # Skip the current record. This is similar to a plain-ruby `next` statement.
    def skip
      raise Skip
    end

    ##
    # Stop processing values from the source. This is similar to a plain-ruby `break` statement.
    def stop
      raise Stop
    end

    ##
    # Flush all currently put values to the sink, optionally resetting as well.
    def flush(reset: true)
      return unless @dirty

      @sink << @collector
      self.reset if reset
    end

    ##
    # Clear the collection of currently-put values.
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
