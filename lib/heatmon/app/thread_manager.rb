module Heatmon
  class App
    class ThreadManager
      include Logger::DSL
      attr_reader :app, :conditions, :logger

      # @!group Setup

      def initialize app
        @app = app
        @logger = @app.exclusive_logger(nil, true)
        @threads, @safe_threads, @conditions = {}, {}, {}
        [@threads, @safe_threads, @conditions].each {|o| o.extend(MonitorMixin) }
        @stopped = register_cond(@threads)
        enable_signal_trapping!
        spawn_signal_listener!
      end

      def enable_signal_trapping!
        Signal.trap("INT") {|sig| @app.shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TERM") {|sig| @app.shutdown!("#{Signal.signame(sig)}") }
        Signal.trap("TSTP") {|sig| @app.shutdown!("#{Signal.signame(sig)}") }

        Signal.trap("USR1") do |sig|
          if $heatmon_debug && $heatmon_debug_was.nil?
            $heatmon_debug_was = true
            $heatmon_debug = false
          else
            $heatmon_debug_was = false
            $heatmon_debug = true
          end
        end
      end

      def spawn_signal_listener!
        spawn :signal_listener, safe: true do
          loop do
            if @app.shutdown.is_a?(String)
              warn "Terminating #{Process.pid} (#{@app.shutdown})..."
              broadcast_conds
              spawn_shutdown_announcer
              @app.instance_eval { @shutdown = true }
            end
            if !$heatmon_debug_was.nil?
              if $heatmon_debug_was
                log "Debug messages disabled"
              else
                log "Debug messages enabled"
              end

              $heatmon_loggers.synchronize do
                $heatmon_loggers.each do |scope, logger|
                  logger.synchronize { $heatmon_debug_was ? logger.disable(:debug) : logger.enable(:debug) }
                end
              end

              $heatmon_debug_was = nil
            end
            sleep 0.5
          end
        end
      end

      def spawn_shutdown_announcer
        spawn :shutdown_announcer, safe: true do
          spool = true
          sleep 1 # give spool chance to exit
          loop do
            begin
              mtr = Thread.main[:ready_to_exit]
              alc = alive.count
              msg = "Waiting for "
              msg << "main thread and " unless mtr
              msg << "#{alive.length}#{" other" unless mtr} thread#{"s" if alc != 1} "
              msg << "(#{alive.keys.join(", ")}) " if $heatmon_debug
              msg << "to exit..."
              spool ? log(msg) : ::Kernel.puts(msg) if alc > 0
            rescue Heatmon::Error::HaltingError => e
              spool = false
              retry
            end
            sleep 5
          end
        end
      end

      # @!endgroup

      # @!group Conditions

      def register_cond monitor
        monitor.new_cond.tap do |cond|
          @conditions.synchronize do
            @conditions[monitor] ||= []
            @conditions[monitor] << cond
          end
        end
      end

      def signal_conds
        @conditions.synchronize do
          @conditions.each do |mon, conds|
            mon.synchronize { conds.each(&:signal) }
          end
        end
      end

      def broadcast_conds
        @conditions.synchronize do
          @conditions.each do |mon, conds|
            mon.synchronize { conds.each(&:broadcast) }
          end
        end
      end

      # @!endgroup

      # @!group Thread handling

      def spawn name, opts = {}, &content
        t = nil
        opts = opts.reverse_merge(critical: Thread.abort_on_exception, safe: false)
        lock = opts[:safe] ? @safe_threads : @threads
        lock.synchronize do
          return if lock[name.to_sym]
          t = Thread.new do
            Thread.current[:name] = name
            Thread.current.abort_on_exception = opts[:critical]
            content.call
          end
          lock[name.to_sym] = t
          @stopped.signal unless opts[:safe]
        end
        t
      end

      def wait_for_threads_to_exit
        until alive.empty?
          if alive(except: [:log_spool]).empty? && @app.shutdown == true
            Thread.pass
            @app.log_spool.halt!
          end
          Thread.pass
          sleep 0.25
        end
      end

      def all opts = {}
        @threads.tap do |t|
          return t.slice(*opts[:only]) if opts[:only]
          return t.except(*opts[:only]) if opts[:except]
        end
      end

      def alive opts = {}
        @threads.select{|n, t| t.status }.tap do |t|
          return t.slice(*opts[:only]) if opts[:only]
          return t.except(*opts[:except]) if opts[:except]
        end
      end

      # @!endgroup
    end
  end
end
