# frozen_string_literal: true

require "json"

module Micdrop
  module Ext
    ##
    # A module for working with the JSON-Lines (ND-JSON) format
    module JsonLines
      ##
      # Takes a file, such as a pipe to another process, and interpret the results as JSON-Lines (ND-JSON)
      class JsonLinesSource
        def initialize(file)
          @file = file
        end

        def self.from_command(*args, **kwargs)
          self.class.new(IO.popen(*args, **kwargs))
        end

        def each
          return enum_for unless block_given?

          @file.each_line do |line|
            yield JSON.parse line
          end
        end
      end

      ##
      # Output data in JSON-Lines (ND-JSON) format
      class JsonLinesSink
        def initialize(file)
          @file = file
        end

        def <<(item)
          JSON.dump(item, @file)
          @file << "\n"
        end
      end
    end
  end
end