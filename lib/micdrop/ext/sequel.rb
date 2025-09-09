# frozen_string_literal: true

require "sequel"

module Micdrop::Ext
  module Sequel
    # A sink which will exclusively insert new items into the database
    class InsertSink
      def initialize(dataset)
        @dataset = dataset
      end

      def <<(collector)
        @dataset.insert(**collector)
      end
    end

    # A sink which will always issue an update statement
    class UpdateSink
      def initialize(dataset, key_columns)
        @dataset = dataset
        @key_columns = if key_columns.is_a? Symbol
                         [key_columns]
                       elsif key_columns.respond_to? :each
                         key_columns
                         # TODO: else throw error
                       end
      end

      def <<(collector)
        dataset = @dataset
        @key_columns.each do |col|
          dataset = dataset.where(**{ col => collector[col] })
        end
        dataset.update(**collector)
      end
    end

    # A sink which will update an item if it exists, or insert it otherwise
    class InsertUpdateSink
      def initialize(dataset, key_columns)
        @dataset = dataset
        @key_columns = if key_columns.is_a? Symbol
                         [key_columns]
                       elsif key_columns.respond_to? :each
                         key_columns
                         # TODO: else throw error
                       end
      end

      def <<(collector)
        dataset = @dataset
        @key_columns.each do |col|
          dataset = dataset.where(**{ col => collector[col] })
        end
        existing = dataset.first
        if existing.nil?
          dataset.insert(**collector)
        else
          # TODO: selectively update specific columns based on existing values
          # e.g. only update if current value is null
          dataset.update(**collector)
        end
      end
    end
  end
end
