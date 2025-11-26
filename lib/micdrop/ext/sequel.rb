# frozen_string_literal: true

require "sequel"

module Micdrop
  module Ext
    module Sequel
      ##
      # A sink which will exclusively insert new items into the database
      class InsertSink
        def initialize(dataset)
          @dataset = dataset
        end

        def <<(collector)
          @dataset.insert(**collector)
        end
      end

      ##
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

      ##
      # A sink which will update an item if it exists, or insert it otherwise
      class InsertUpdateSink
        def initialize(dataset, key_columns, update_actions: {}, default_update_action: :coalesce,
                       match_empty_key: false)
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
          existing = dataset.limit(2).all
          if existing.count > 1
            raise Micdrop::SinkError, "Key column(s) of this InsertUpdateSink are not unique"
          elsif existing.empty?
            dataset.insert(**collector)
          else
            dataset.update(**update_merge(existing.first, collector))
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
            when :overwrite_nulls then oldval.nil? ? newval : oldval
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

  ##
  # Sequel-specific extensions for ItemContext
  class ItemContext
    def db_lookup(dataset, key_col, val_col, pass_if_not_found: false, warn_if_not_found: nil, apply_if_not_found: nil)
      # TODO: allow registering db_lookups like we do normal lookups
      warn_if_not_found = true if warn_if_not_found.nil? && apply_if_not_found.nil?
      found = dataset.where(key_col => @value).get(val_col)
      if found.nil?
        warn format "Value %s not found in db_lookup", @value if warn_if_not_found
        if !apply_if_not_found.nil?
          apply apply_if_not_found
        elsif !pass_if_not_found
          @value = nil
        end
      else
        @value = found
      end
      self
    end
  end
end
