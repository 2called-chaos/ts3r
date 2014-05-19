module Heatmon
  class App
    module Setup
      extend ActiveSupport::Concern

      # register attribute reader
      included do
        attr_reader :config, :tman, :lman, :log_spool, :shutdown
      end

      # @!group Setup

      def initialize
        @shutdown = false
        @log_spool = KernelStub
        setup_logger(logger)
        debug logger.startup.strftime("%F %T.%L %Z %z")
        debug "Heatmon #{Heatmon::VERSION} created (pid #{Process.pid})!"
        debug "Using #{RUBY_DESCRIPTION}"
      end

      # initial logger setup
      # @param [Banana::Logger] logger logger instance to setup
      def setup_logger l
        l.synchronize do
          l.disable(:debug) unless $heatmon_debug
          l.log_level severe: "red"
          l.attach @log_spool if @log_spool
        end
      end

      # Inits application. We couldn't use {#initialize} because
      # the main configuration would init a second instance.
      def init!
        init_config!
        init_concurrency!
      end

      # Defines and parses command line arguments/parameters via OptParse.
      def init_parameters! argv
        @opts = {
          help: false,
          version: false,
          daemonize: false,
          testloop: false,
          configtest: [],
        }

        @optparse = OptionParser.new do |opts|
          opts.banner = "Usage: heatmon [options]"

          opts.on("-c", "--configtest file,file2", Array, "Test if config files are parseable.", "Relative to config directory (e.g.: example/simple)") {|v| @opts[:configtest] = v }
          opts.on("-d", "--daemonize", "Start in daemon mode") { @opts[:daemonize] = true }
          opts.on(      "--debug", "Show extended debug messages") {} # used in lib/heatmon.rb
          opts.on("-h", "--help", "Shows this help") { @opts[:help] = true }
          opts.on("-v", "--version", "Shows version and other info") { @opts[:version] = true }
          opts.on("--testloop", "Development test task") { @opts[:testloop] = true }
        end

        begin
          @optparse.parse!(argv)
        rescue OptionParser::ParseError => e
          abort(e.message)
          dispatch_help
          finalize(10)
        end
      end

      # Inits everything needed to run the daemon.
      def init_daemon!
        # perform basic selftest
        perform_selftest

        # load custom configurations
        load_custom_configs
      end

      # Reload daemon
      def reinit_daemon!
        debug "Reinitialising daemon..."
        raise NotImplementedError

        # cancel all tasks
        #

        # wait for running tasks to end
        #

        # clear config & load main configuration
        init_config!

        # load configuration
        #

        debug "Daemon reinitalised"
      end

      # Inits config object and apply heatmon config from file
      def init_config!
        debug "Loading Heatmon configuration..."
        @config = Configuration.new(self)
        load get_config("heatmon")
        debug "Heatmon configuration loaded"
      rescue Exception => e
        config_trace("heatmon.rb", $!, true)
      end

      # load configuration files except main configuration
      def load_custom_configs *a
        exclusive_logger do |l|
          l.debug "loading custom configurations..."
          l.ensure_prefix("[CCONF] ".magenta) do
            custom_configs(*a).each do |file|
              bfile = cfg_basedir(file)
              l.debug "parsing #{bfile.magenta}"
              begin
                load file
              rescue ScriptError, StandardError
                if $!.message[/cannot load such file/]
                  l.warn "not found".red
                else
                  config_trace(bfile, $!, @config.get("heatmon.configuration.abort_on_error"))
                end
              end
            end
          end
          l.debug "custom configurations loaded"
        end
      end

      # Initializes concurrency support handlers and reconfigures logger.
      def init_concurrency!
        Thread.abort_on_exception = true
        Thread.main[:ready_to_exit] = false
        debug "Initializing concurrency core..."
        logger.ensure_prefix("#{logger.prefix}  ") do
          debug "Initializing thread manager..."
          @tman = ThreadManager.new(self)

          debug "Initializing lock manager..."
          @lman = LockManager.new(self)

          debug "Initializing log spool..."
          @log_spool = LogSpool.new(self)

          debug "Synchronizing loggers..."
          $heatmon_loggers.synchronize do
            $heatmon_loggers.each do |scope, li|
              li.synchronize { li.attach @log_spool if @log_spool }
            end
          end
        end
        Thread.main[:concurrency_core_ready] = true
        debug "Concurrency core ready"
      end

      # @!endgroup
    end
  end
end
