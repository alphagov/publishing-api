module Commands
  class Callback
    include Enumerable

    def initialize
      @callbacks = []
    end

    def each(&block)
      @callbacks.each(&block)
    end

    def <<(block)
      @callbacks << block
    end
  end
end
