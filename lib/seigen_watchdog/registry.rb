# frozen_string_literal: true

module SeigenWatchdog
  # Thread-safe registry for storing named values
  class Registry
    class AlreadyExistsError < SeigenWatchdog::Error; end
    class NotFoundError < SeigenWatchdog::Error; end

    def initialize
      @data = {}
      @mutex = Mutex.new
    end

    # Creates a new entry with the given name and initial value
    # @param name [Symbol, String] the name of the entry
    # @param value [Object] the initial value (default: 0)
    # @raise [AlreadyExistsError] if the name already exists
    def create(name, value = 0)
      @mutex.synchronize do
        raise AlreadyExistsError, "Entry '#{name}' already exists" if @data.key?(name)

        @data[name] = value
      end
    end

    # Replaces the value for the given name using a block
    # @param name [Symbol, String] the name of the entry
    # @yield [old_value] the current value
    # @yieldreturn [Object] the new value
    # @raise [NotFoundError] if the name doesn't exist
    def replace(name)
      @mutex.synchronize do
        raise NotFoundError, "Entry '#{name}' not found" unless @data.key?(name)

        old_value = @data[name]
        @data[name] = yield(old_value)
      end
    end

    # Deletes the entry with the given name
    # @param name [Symbol, String] the name of the entry
    # @raise [NotFoundError] if the name doesn't exist
    def delete(name)
      @mutex.synchronize do
        raise NotFoundError, "Entry '#{name}' not found" unless @data.key?(name)

        @data.delete(name)
      end
    end

    # Gets the value for the given name (for internal use)
    # @param name [Symbol, String] the name of the entry
    # @return [Object, nil] the value or nil if not found
    def get(name)
      @mutex.synchronize { @data[name] }
    end
  end
end
