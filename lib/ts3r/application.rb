module Ts3r
  # Logger Singleton
  MAIN_THREAD = ::Thread.main
  def MAIN_THREAD.app_logger
    MAIN_THREAD[:app_logger] ||= Banana::Logger.new
  end

  class Application
    attr_reader :opts, :config, :connection, :mutex
    include Dispatch
    include Helpers

    # =========
    # = Setup =
    # =========
    def self.dispatch *a
      new(*a) do |app|
        app.parse_params
        app.logger
        begin
          app.dispatch
        rescue Interrupt
          app.abort("Interrupted", 1)
        end
      end
    end

    def initialize env, argv
      @env, @argv = env, argv
      @mutex = Mutex.new
      @opts = {
        dispatch: :index,
        check_for_updates: true,
      }
      yield(self)
    end

    def load_configuration!
      unless Thread.main[:app_config]
        Thread.main[:app_config] = @config = Configuration.new
        debug "loading configurations..."

        # load all configs
        bot_config = "#{Ts3r::ROOT}/config/bot.rb"
        require bot_config
        r = Dir.glob("#{Ts3r::ROOT}/config/**/*.rb")
        r.delete(bot_config)
        r.each {|f| require f }

        debug "configurations loaded"
      end
      Thread.main[:app_config]
    end

    def establish_connection!
      if @connection.nil?
        begin
          @connection = TS3Query.connect(
            address:  @config.get("ts3r.server.host"),
            port:     @config.get("ts3r.server.port"),
            username: @config.get("ts3r.server.username"),
            password: @config.get("ts3r.server.password")
          )
          begin
            @connection.clientupdate(client_nickname: @config.get("ts3r.botname"))
          rescue Net::ReadTimeout
            warn "Failed to update client nickname"
          end
        rescue ConnectionRefused
          abort "Connection refused, check configuration.", 1
        end
      end
      @connection
    end

    def reconnect!
      @connection = nil
      establish_connection!
    end

    def synchronize &block
      @mutex.synchronize(&block)
    end

    def parse_params
      @optparse = OptionParser.new do |opts|
        opts.banner = "Usage: ts3r [options]"

        opts.on("-c", "--console", "Open interactive shell to play around") { @opts[:dispatch] = :console }
        opts.on("-m", "--monochrome", "Don't colorize output") { logger.colorize = false }
        opts.on("-h", "--help", "Shows this help") { @opts[:dispatch] = :help }
        opts.on("-v", "--version", "Shows version and other info") { @opts[:dispatch] = :info }
        opts.on("-z", "Do not check for updates on GitHub (with -v/--version)") { @opts[:check_for_updates] = false }
      end

      begin
        @optparse.parse!(@argv)
      rescue OptionParser::ParseError => e
        abort(e.message)
        dispatch(:help)
        exit 1
      end
    end

    # ==========
    # = Logger =
    # ==========
    [:log, :warn, :abort, :debug].each do |meth|
      define_method meth, ->(*a, &b) { Thread.main.app_logger.send(meth, *a, &b) }
    end

    def logger
      Thread.main.app_logger
    end

    # Shortcut for logger.colorize
    def c str, color = :yellow
      logger.colorize? ? logger.colorize(str, color) : str
    end

    def ask question
      logger.log_with_print(false) do
        log c("#{question} ", :blue)
        STDOUT.flush
        STDIN.gets.chomp
      end
    end
  end
end
