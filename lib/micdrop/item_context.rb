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

    # Debug tool to print the current value to the console
    def inspect
      puts @value
    end

    ### Basic transformers ###

    def parse_int(base = 10)
      return if @value.nil?

      @value = @value.to_i(base)
    end

    def parse_float
      return if @value.nil?

      @value = @value.to_f
    end

    # Parse a date using a given format string
    def parse_date(format = "%Y-%m-%d", zero_date: false)
      if zero_date
        zero = make_zero_date format
        @value = nil if @value == zero
      end
      @value = ::Date.strptime(@value, format) unless @value.nil?
    end

    # Parse a datetime using a given format string
    def parse_datetime(format = "%Y-%m-%d %H:%M:%S", zero_date: false)
      if zero_date
        zero = make_zero_date format
        @value = nil if @value == zero
      end
      @value = ::DateTime.strptime(@value, format) unless @value.nil?
    end

    # Format a date using a given format string
    def format_date(format = "%Y-%m-%d", zero_date: false)
      if @value.nil? && zero_date
        @value = make_zero_date format
      elsif !@value.nil?
        @value = @value.strftime(format)
      end
    end

    # Format a datetime using a given format string
    def format_datetime(format = "%Y-%m-%d %H:%M:%S", zero_date: false)
      if @value.nil? && zero_date
        @value = make_zero_date format
      elsif !@value.nil?
        @value = @value.strftime(format)
      end
    end

    # Parse a value into a boolean using a list of common values for true or false
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

    # Format a boolean as a string
    def format_boolean(true_value = "Yes", false_value = "No")
      if @value.nil?
        nil
      elsif @value
        @value = true_value
      else
        @value = false_value
      end
    end

    # Format the value into a string using sprintf-style formatting, or using `to_s` if no template is provided.
    def format_string(template = nil)
      return if @value.nil?

      @value = if template.nil?
                 @value.to_s
               else
                 template % @value
               end
    end

    # Lookup the value in a hash
    def lookup(mapping, pass_if_not_found: false)
      return if @value.nil?

      @value = mapping.fetch @value do |v|
        v if pass_if_not_found
      end
    end

    # Perform a string replacement or regex replacement on the current value
    def string_replace(find, replace)
      @value = @value.gsub find, replace unless value.nil?
    end

    # Provide a default value if the current value is nill
    def default(default_value)
      @value = default_value if @value.nil?
    end

    ### String (de)structuring ###

    # Split a string according to a delimeter. Accepts an optional block in the record context of the newly created list
    # of values.
    def split(delimiter, &block)
      return if @value.nil?

      @value = @value.split(delimiter)
      enter(&block) unless block.nil?
    end

    # Join a list into a string
    def join(delimiter)
      @value = @value.join(delimiter) unless @value.nil?
    end

    # Split a string into a set of key/value pairs (as a hash) according to a set of delimiters. Accepts an optional
    # block in the record context of the newly created hash of values.
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

    # Join a hash into a string
    def join_kv(kv_delimiter, item_delimiter = "\n")
      return if @value.nil?

      string = ""
      @value.each_pair do |k, v|
        string += item_delimiter if string != ""
        string += k.to_s + kv_delimiter + v
      end
      @value = @value.join(delimiter)
    end

    # TODO: JSON and Regex match

    private

    def make_zero_date(format)
      ::DateTime.new(2000, 2, 2, 2, 2, 2).strftime(format).gsub!("2", "0")
    end
  end
end
