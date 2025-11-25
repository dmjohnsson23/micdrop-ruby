# frozen_string_literal: true

module Micdrop
  ##
  # An error on the sink side of the migration
  class SinkError < StandardError
  end

  ##
  # An error on the source side of the migration
  class SourceError < StandardError
  end

  ##
  # An error with the current data value that prevents conversion operations from working
  class ValueError < StandardError
  end
end
