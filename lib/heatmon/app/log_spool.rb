module Heatmon
  class App
    class LogSpool
      include Logger::DSL
      attr_reader :app, :logger

      def initialize app
        @messages = Queue.new
        @messages.extend(MonitorMixin)

        @app = app
        @logger = @app.exclusive_logger(nil, true)
        @shutdown = false
        @channel = ::Kernel
        @channel_lock = Monitor.new
        @halted = @app.tman.register_cond(@messages)
        @stream = @app.tman.register_cond(@messages)

        app.tman.spawn(:log_spool) { loop { work } }
      end

      def work
        if @halted == true
          @app.mayexit
        end

        @channel_lock.synchronize {
          l = @messages.pop(true)
          if l[0] == :trx
            l[1].each {|a| @channel.send(*a) }
          else
            @channel.send(*l)
          end
          # @channel.send(:puts, "LogSpool can't keep up (#{@messages.length} enqued)") if @messages.length > 100
        }
        @messages.synchronize { @halted.try(:signal) }
        @messages.synchronize { @stream.wait_until { @halted == true || @app.shutdown || !@messages.empty? } }
      rescue ThreadError
        raise unless $!.message == "queue empty"
      end

      def exclusive
        @channel_lock.synchronize do
          yield if block_given?
        end
      end

      def halt!
        return @messages.synchronize { @stream.signal } if @halted == true
        return if @shutdown
        ilog "halting log spool (#{@messages.length} enqued)", :debug
        @shutdown = true
        @messages.synchronize do
          @halted.wait_until do
            @messages.length == 0
          end
        end
        @halted = true
        @messages.synchronize { @stream.signal }
      end

      def priority msg, method = :puts
        raise Error::HaltingError, "log spool is shutting down" if @shutdown
        @messages.unshift [method, msg]
        @messages.synchronize { @stream.signal }
      end

      def enq_ary array
        raise Error::HaltingError, "log spool is shutting down" if @shutdown
        @messages << [:trx, array]
        @messages.synchronize { @stream.signal }
      end

      def queue msg, method = :puts
        raise Error::HaltingError, "log spool is shutting down" if @shutdown
        @messages << [method, msg]
        @messages.synchronize { @stream.signal }
      end
      alias_method :puts, :queue

      def warn msg
        queue msg, :warn
      end

      def print msg
        queue msg, :print
      end
    end
  end
end
