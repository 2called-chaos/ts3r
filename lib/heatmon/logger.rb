module Heatmon
  # This class provides a simple logger which maintains and displays the runtime of the logger instance.
  class Logger
    Banana.require_on(self, %w[dsl])
    attr_reader :startup, :channel, :method, :logged
    attr_accessor :colorize, :prefix

    # Foreground color values
    COLORMAP = {
      black: 30,
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      white: 37,
    }

    # Initializes a new logger instance. The internal runtime measurement starts here!
    #
    # There are 4 default log levels: info (yellow), warn & abort (red) and debug (blue).
    # All are enabled by default. You propably want to {#disable disable(:debug)}.
    def initialize
      @startup = Time.now.utc
      @concurrent = false
      @colorize = true
      @prefix = ""
      @enabled = true
      @timestr = true
      @channel = ::Kernel
      @method = :puts
      @logged = 0
      @mutex = Monitor.new
      @default_type = :info
      @levels = {}
      @queue = []
      log_level info: "yellow", warn: "red", abort: "red", debug: "blue"
    end

    def fork
      l = nil
      synchronize do
        l = self.class.new
        [:@startup, :@concurrent, :@colorize, :@enabled, :@timestr, :@method, :@levels, :@default_type].each do |var|
          l.instance_variable_set(var, instance_variable_get(var).deep_dup)
        end
        l.instance_variable_set(:@channel, instance_variable_get(:@channel))
        l.log_level
      end
      yield l if block_given?
      l
    end

    # The default channel is `Kernel` which is Ruby's normal `puts`.
    # Attach it to a open file with write access and it will write into
    # the file. Ensure to close the file in your code.
    #
    # @param channel Object which responds to puts and print
    def attach channel
      synchronize { @channel = channel }
    end

    # Get synchronized access for the whole logger or act as proxy if concurrent mode is not enabled.
    def synchronize &block
      @mutex.synchronize(&block)
    end

    # Print raw message onto {#channel} using {#method}.
    #
    # @param [String] msg Message to send to {#channel}.
    # @param [Symbol] method Override {#method}.
    def raw msg, method = @method
      synchronize do
        if @transaction_enabled
          @queue << [method, msg]
        else
          @channel.send(method, msg)
        end
      end
    end

    # Wait for block to finish and then push everything into the queue
    def transaction
      synchronize do
        begin
          @transaction_enabled = true
          yield if block_given?
        ensure
          @transaction_enabled = false
          commit
        end
      end
    end

    # send queue to channel
    def commit
      synchronize do
        @channel.enq_ary @queue
        @queue = []
      end
    end

    # Add additional log levels which are automatically enabled.
    # @param [Hash] levels Log levels in the format `{ debug: "red" }`
    def log_level levels = {}
      synchronize do
        levels.each do |level, color|
          @levels[level.to_sym] ||= { enabled: true }
          @levels[level.to_sym][:color] = color
        end
        @lshift = @levels.keys.map(&:to_s).map(&:length).max
      end
    end

    # Calls the block with the given type enforced and ensures that the type
    # will be the same as before.
    #
    # @param [Symbol] type Log type to use for the block
    # @param [Proc] block Block to call
    def ensure_type type, &block
      synchronize do
        begin
          old_type, @default_type = @default_type, type
          block.call
        ensure
          @default_type = old_type
        end
      end
    end

    # Calls the block with the given prefix and ensures that the prefix
    # will be the same as before.
    #
    # @param [String] prefix Prefix to use for the block
    # @param [Proc] block Block to call
    def ensure_prefix prefix, &block
      synchronize do
        begin
          old_prefix, @prefix = @prefix, prefix
          block.call
        ensure
          @prefix = old_prefix
        end
      end
    end

    # Calls the block after changing the output method.
    # It also ensures to set back the method to what it was before.
    #
    # @param [Symbol] method Method to call on {#channel}
    def ensure_method method, &block
      synchronize do
        begin
          old_method, old_logged = @method, @logged
          @method, @logged = method, 0
          block.call
        ensure
          @method = old_method
          @logged += old_logged
        end
      end
    end

    # Calls the block after changing the output method to `:print`.
    # It also ensures to set back the method to what it was before.
    #
    # @param [Boolean] clear If set to true and any message was printed inside the block
    #   a \n newline character will be printed.
    def log_with_print clear = true, &block
      synchronize do
        ensure_method :print do
          begin
            block.call
          ensure
            raw("", :puts) if clear && @logged > 0
          end
        end
      end
    end

    # Calls the block after disabling the runtime indicator.
    # It also ensures to set back the old setting after execution.
    def log_without_timestr &block
      synchronize do
        begin
          timestr, @timestr = @timestr, false
          block.call
        ensure
          @timestr = timestr
        end
      end
    end

    # @return [Boolean] returns true if the log level format :debug is enabled.
    def debug?
      enabled? :debug
    end

    # If a `level` is provided it will return true if this log level is enabled.
    # If no `level` is provided it will return true if the logger is enabled generally.
    #
    # @return [Boolean] returns true if the given log level is enabled
    def enabled? level = nil
      level.nil? ? @enabled : @levels[level.to_sym][:enabled]
    end

    # Same as {#enabled?} just negated.
    def disabled? level = nil
      !enabled?(level)
    end

    # Same as {#enable} just negated.
    #
    # @param [Symbol, String] level Loglevel to disable.
    def disable level = nil
      synchronize do
        if level.nil?
          @enabled = false
        else
          @levels[level.to_sym][:enabled] = false
        end
      end
    end

    # Enables the given `level` or the logger generally if no `level` is given.
    # If the logger is disabled no messages will be printed. If it is enabled
    # only messages for enabled log levels will be printed.
    #
    # @param [Symbol, String] level Loglevel to enable.
    def enable level = nil
      synchronize do
        if level.nil?
          @enabled = true
        else
          @levels[level.to_sym][:enabled] = true
        end
      end
    end

    # Colorizes the given string with the given color. It uses the build-in
    # colorization feature. You may want to use the colorize gem.
    #
    # @param [String] str The string to colorize
    # @param [Symbol, String] color The color to use (see {COLORMAP})
    # @raise [ArgumentError] if color does not exist in {COLORMAP}.
    def colorize str, color
      ccode = COLORMAP[color.to_sym] || raise(ArgumentError, "Unknown color #{color}!")
      "\e[#{ccode}m#{str}\e[0m"
    end

    # This method is the only method which sends the message `msg` to `@channel` via `@method`.
    # It also increments the message counter `@logged` by one.
    #
    # This method instantly returns nil if the logger or the given log level `type` is disabled.
    #
    # @param [String] msg The message to send to the channel
    # @param [Symbol] type The log level
    def log msg, type = @default_type
      synchronize do
        return if !@enabled || !@levels[type][:enabled]
        if @levels[type.to_sym] || !@levels.key?(type.to_sym)
          time = Time.at(Time.now.utc - @startup).utc
          timestr = @timestr ? "[#{time.strftime("%H:%M:%S.%L")} #{type.to_s.upcase}]#{"".ljust(@lshift - type.to_s.length + 3)}" : ""

          if @colorize
            msg = "#{colorize(timestr, @levels[type.to_sym][:color])}" <<
                  "#{@prefix}" <<
                  "#{colorize(msg, @levels[type.to_sym][:color])}"
          else
            msg = "#{timestr}#{@prefix}#{msg}"
          end
          @logged += 1
          raw msg, @method
        end
      end
    end
    alias_method :info, :log

    # Shortcut for {#log #log(msg, :debug)}
    #
    # @param [String] msg The message to send to {#log}.
    def debug msg
      synchronize { log(msg, :debug) }
    end

    # Shortcut for {#log #log(msg, :warn)} but sets channel method to "warn".
    #
    # @param [String] msg The message to send to {#log}.
    def warn msg
      synchronize { ensure_method(:warn) { log(msg, :warn) } }
    end

    # Shortcut for {#log #log(msg, :severe)} but sets channel method to "warn".
    #
    # @param [String] msg The message to send to {#log}.
    def severe msg
      synchronize { ensure_method(:warn) { log(msg, :severe) } }
    end

    # Shortcut for {#log #log(msg, :abort)} but sets channel method to "warn".
    #
    # @param [String] msg The message to send to {#log}.
    # @param [Integer] exit_code Exits with given code or does nothing when falsy.
    def abort msg, exit_code = false
      synchronize do
        ensure_method(:warn) { log(msg, :abort) }
        Heatmon.app.finalize(exit_code) if exit_code
      end
    end

    # Shortcut to prioritize important message
    # @param [String] msg The message to send to {#log}.
    # @param [Symbol] type The log level
    def ilog msg = nil, type = @default_type
      synchronize do
        ensure_method(:priority) {
          yield self if block_given?
          log(msg, type) if msg
        }
      end
    end
  end
end
