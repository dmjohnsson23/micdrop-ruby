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
      def initialize(dataset, key_columns, update_actions: {}, default_update_action: :coalesce, match_empty_key: false)
        @dataset = dataset
        @key_columns = if key_columns.is_a? Symbol
                         [key_columns]
                       elsif key_columns.respond_to? :each
                         key_columns
                         # TODO: else throw error
                       end
        @update_actions = update_actions
        @default_update_action = default_update_action
        @match_empty_key = match_empty_key
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
          dataset.update(**update_merge(existing, collector))
        end
      end

      private

      def update_merge(existing, collector)
        if @update_actions.empty?
          # If we don't have per-column actions, we can take shortcuts for some actions types
          return collector if @default_update_action == :always_overwrite
          return collector.compact if @default_update_action == :coalesce
        end
        # Otherwise merge according to the rules specified
        existing.merge(collector) do |key, oldval, newval|
          case @update_actions.fetch(key, @default_update_action)
          when :coalesce then newval.nil? ? oldval : newval
          when :overwrite_nulls then olval.nil? ? newval : oldval
          when :always_overwrite then newval
          when :keep_existing then oldval
          when :append then format("%s %s", oldval, newval)
          when :append_line then format("%s\n%s", oldval, newval)
          when :prepend then format("%s %s", newval, oldval)
          when :prepend_line then format("%s\n%s", newval, oldval)
          when :add then oldval + newval
          end
        end
      end
    end
  end
end

# TODO: maybe we can make ItemContext methods for common tasks (e.g. lookup in the db)
# These are pretty easy to do already, but we'll see.
