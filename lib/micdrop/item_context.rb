# frozen_string_literal: true

require "date"

module Micdrop
  class ItemContext # rubocop:disable Metrics/ClassLength
    def initialize(record, value)
      @record = record
      @value = value
      @original_value = value
    end

    attr_reader :record, :original_value
    attr_accessor :value

    # Directly update the current value
    def update(value)
      @value = value
    end

    # Use plain Ruby code to modify this Item.
    def convert(proc_or_symbol = nil, &block)
      @value = proc_or_symbol.call(@value) unless proc_or_symbol.nil?
      @value = block.call(@value) unless block.nil?
    end

    # Run a predefined pipline on this Item.
    def apply(pipeline)
      instance_eval(&pipeline)
    end

    # Treat the current Item as a Record, allowing child objects to be Taken.
    def enter(&block)
      # TODO: create a collection context that allows child items to be taken and put
    end

    # Create a new item context with the same value as exists currently. Allows operations in a
    # scope that will not affect the value in the current scope.
    def scope(&block)
      ctx = ItemContext.new(@record, @value)
      ctx.apply block
      ctx
    end

    # Similar to Take, but replaces the current value in the current scope
    #
    # Can be used to take slices of arrays as well
    def extract(name)
      return if @value.nil?

      @value = @value[name]
    end

    ### record passthru ###

    def put(name)
      # TODO: allow second parameter with different value
      @record.put name, @value
    end

    def skip
      # TODO
      @record.skip
    end

    def stop
      # TODO
      @record.stop
    end

    # TODO: should we passthru `take`?

    ### Debug transformers ###

    def inspect
      puts @value
    end

    ### Basic transformers ###

    def parse_date(format = "%Y-%m-%d", zero_date: false)
      if zero_date
        zero = make_zero_date format
        @value = nil if @value == zero
      end
      @value = ::Date.strptime(@value, format) unless @value.nil?
    end

    def parse_datetime(format = "%Y-%m-%d %H:%M:%S", zero_date: false)
      if zero_date
        zero = make_zero_date format
        @value = nil if @value == zero
      end
      @value = ::DateTime.strptime(@value, format) unless @value.nil?
    end

    def format_date(format = "%Y-%m-%d", zero_date: false)
      if @value.nil? && zero_date
        @value = make_zero_date format
      elsif !@value.nil?
        @value = @value.strftime(format)
      end
    end

    def format_datetime(format = "%Y-%m-%d %H:%M:%S", zero_date: false)
      if @value.nil? && zero_date
        @value = make_zero_date format
      elsif !@value.nil?
        @value = @value.strftime(format)
      end
    end

    def parse_boolean(true_values = [1, "1", "true", "True", "TRUE", "yes", "Yes", "YES", "on", "On", "ON"],
                      false_values = [0, "0", "false", "False", "FALSE", "no", "No", "NO", "off", "Off", "OFF", ""])
      if true_values.include? @value
        @value = true
      elsif false_values.include? @value
        @value = false
      elsif @value.nil?
        nil
      else
        raise ValueError("Unrecognized value: {repr(value)}")
      end
    end

    def format_boolean(true_value = "Yes", false_value = "No")
      if @value.nil?
        nil
      elsif @value
        @value = true_value
      else
        @value = false_value
      end
    end

    def lookup(mapping, pass_if_not_found: false)
      return if @value.nil?

      @value = mapping.fetch @value do |v|
        v if pass_if_not_found
      end
    end

    def string_replace(find, replace)
      @value = @value.gsub find, replace unless value.nil?
    end

    def default(default_value)
      @value = default_value if @value.nil?
    end

    ### String (de)structuring ###

    def split(delimiter, &block)
      return if @value.nil?

      @value = @value.split(delimiter)
      enter(&block) unless block.nil?
    end

    def join(delimiter)
      @value = @value.join(delimiter) unless @value.nil?
    end

    def split_kv(kv_delimiter, item_delimiter = "\n", &block)
      return if @value.nil?

      kv = {}
      @value.each_line(item_delimiter, chomp: true) do |item|
        k, v = item.split(kv_delimiter, 2)
        kv[k] = v
      end
      @value = kv
      enter(&block) unless block.nil?
    end

    def join_kv(kv_delimiter, item_delimiter = "\n")
      return if @value.nil?

      string = ""
      @value.each_pair do |k, v|
        string += item_delimiter if string != ""
        string += k.to_s + kv_delimiter + v
      end
      @value = @value.join(delimiter)
    end

    # TODO: JSON and Regex

    private

    def make_zero_date(format)
      ::DateTime.new(2000, 2, 2, 2, 2, 2).strftime(format).gsub!("2", "0")
    end
  end
end
