# Encoding: utf-8
module Heatmon
  class Logger
    module DSL
      extend ActiveSupport::Concern

      included do
        # delegate methods to {#logger}
        [:log, :warn, :abort, :debug, :severe, :ilog].each do |meth|
          define_method meth, ->(*a, &b) { (Thread.current[:logger] || Thread.main[:logger] || KernelStub).send(meth, *a, &b) }
        end
      end

      # Singleton accessor for {Heatmon::Logger} objects
      # @param [Symbol, Object] scope Logger scope
      # @param [Logger] parent Parent logger to fork from
      # @yield [Heatmon::Logger] The logger instance in a synchronized block
      # @return [Heatmon::Logger] The logger instance
      def logger scope = :default, parent = nil, &block
        # initialize hash
        if !$heatmon_loggers
          $heatmon_loggers = {}
          $heatmon_loggers.extend(MonitorMixin)
        end

        # random scope
        if scope.nil?
          $heatmon_loggers.synchronize do
            begin
              scope = Banana::Generator.uniqid
              raise if $heatmon_loggers.key?(scope)
            rescue
              retry
            end
          end
        end

        # singleton logger
        if !$heatmon_loggers[scope]
          $heatmon_loggers.synchronize do
            if parent
              $heatmon_loggers[scope] = parent.fork
            else
              $heatmon_loggers[scope] = Heatmon::Logger.new
            end
          end
        end
        if block
          begin
            l = Thread.current[:logger]
            Thread.current[:logger] = $heatmon_loggers[scope]
            block.call($heatmon_loggers[scope])
          ensure
            Thread.current[:logger] = l
          end
        else
          Thread.current[:logger] = $heatmon_loggers[scope]
        end
        $heatmon_loggers[scope]
      end

      # Use existing logger as base to get a fully usable logger in threaded environments.
      # This won't be a singleton logger as it has no scope identifier.
      def exclusive_logger parent = nil, keep_thread = false, &block
        ologger = Thread.current[:logger]
        logger(nil, parent || $heatmon_loggers[:default], &block)
      ensure
        Thread.current[:logger] = ologger if keep_thread
      end
    end
  end
end
