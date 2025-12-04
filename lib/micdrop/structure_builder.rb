module Micdrop
  class StructureBuilder
    def initialize(raw_value, parent = nil, exists: true, push_parent: false, parent_key: nil)
      @raw_value = raw_value
      @parent = parent
      @exists = exists
      @push_parent = push_parent
      @parent_key = parent_key
      @enforced_types = nil
    end

    def self.new_blank
      StructureBuilder.new nil, nil, exists: false
    end

    attr_reader :parent, :exists, :raw_value

    def [](*args)
      if args.empty?
        # x[]
        enforce_array
        StructureBuilder.new nil, self, exists: false, push_parent: true
      elsif args.count == 1
        arg = args.first
        if args.first.is_a?(Integer)
          # x[1]
          enforce_array_or_hash
        else
          # x["thing"]
          enforce_hash
        end
        if @exists && @raw_value.is_a?(Array) && arg.is_a?(Integer) && arg < @raw_value.length && arg >= -@raw_value.length
          StructureBuilder.new @raw_value[arg], self, parent_key: arg
        elsif @exists && @raw_value.is_a?(Hash) && @raw_value.has_key?(arg)
          StructureBuilder.new @raw_value[arg], self, parent_key: arg
        else
          StructureBuilder.new nil, self, exists: false, parent_key: arg
        end
      elsif args.count == 2 && args[0].is_a?(Integer) && args[1].is_a?(Integer)
        # x[3, 7] = :something
        enforce_array
        context[*args] = value
      else
        raise IndexError
      end
    end

    def []=(*args)
      value = args.pop
      if args.empty?
        # x[] = :something
        enforce_array
        realize
        @raw_value.push value
      elsif args.count == 1
        arg = args.first
        if arg.is_a?(Integer)
          # x[1] = :something
          enforce_array_or_hash
        else
          # x["thing"] = :something
          enforce_hash
        end
        realize
        @raw_value[arg] = value
      elsif args.count == 2 && args[0].is_a?(Integer) && args[1].is_a?(Integer)
        # x[3, 7] = :something
        enforce_array
        realize
        @raw_value[*args] = value
      else
        raise IndexError
      end
    end

    def <<(value)
      # x << :something
      enforce_array
      realize
      @raw_value.push value
    end

    ##
    # This is intended as an inverse to :dig, automatically assembling structure as needed
    def bury(value, *keys)
      context = self
      last_key = keys.pop
      keys.each do |key|
        context = if key.nil?
                    context[]
                  else
                    context[key]
                  end
      end
      if last_key.nil?
        context[] = value
      else
        context[last_key] = value
      end
    end

    def enforce_array
      raise StandardError, "Value is not an array" if @exists && !@raw_value.is_a?(Array)

      @enforced_types = if @enforced_types.nil?
                          [:array]
                        else
                          [:array].intersection @enforced_types
                        end
    end

    def enforce_hash
      raise StandardError, "Value is not a" if @exists && !@raw_value.is_a?(Hash)

      @enforced_types = if @enforced_types.nil?
                          [:hash]
                        else
                          [:hash].intersection @enforced_types
                        end
    end

    def enforce_array_or_hash
      raise StandardError, "Value is not a" if @exists && !(@raw_value.is_a?(Array) || @raw_value.is_a?(Hash))

      @enforced_types = if @enforced_types.nil?
                          %i[array hash]
                        else
                          %i[array hash].intersection @enforced_types
                        end
    end

    def realize
      return if @exists

      # First make sure the parent is real
      @parent.realize unless @parent.nil? || @parent.exists

      # Then make ourselves real
      if @enforced_types.nil?
        raise StandardError, "No specified type"
      elsif @enforced_types.empty?
        raise StandardError, "No allowed type"
      else
        case @enforced_types.first
        when :array
          @raw_value = []
        when :hash
          @raw_value = {}
        else
          raise StandardError, "Unknown type: #{@enforced_types.first}"
        end
      end

      unless @parent.nil?
        # Then add ourselves to the parent
        if !@parent_key.nil?
          @parent.raw_value[@parent_key] = @raw_value
        elsif @push_parent
          @parent_key = @parent.raw_value.length
          @parent.raw_value << @raw_value
        else
          raise StandardError, "Use either push_parent or parent_key for non-existing values"
        end
      end

      # And now we're done!
      @exists = true
    end
  end
end
