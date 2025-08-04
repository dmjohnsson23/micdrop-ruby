module Micdrop
  class ItemContext
    def initialize(parent, value)
        @parent = parent
        @value = value
        @original_value = value
    end
    def value
        @value
    end
    def update(value)
        @value = value
    end
    def put(name)
      @parent.put @value, name
    end
  end
end