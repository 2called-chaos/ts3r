# Encoding: Utf-8
module Ts3r
  class Application
    module Dispatch
      def dispatch action = (@opts[:dispatch] || :help)
        load_configuration!
        case action
          when :version, :info then dispatch_info
          else
            if respond_to?("dispatch_#{action}")
              send("dispatch_#{action}")
            else
              abort("unknown action #{action}", 1)
            end
        end
      end

      def dispatch_help
        logger.log_without_timestr do
          @optparse.to_s.split("\n").each(&method(:log))
        end
      end

      def dispatch_info
        logger.log_without_timestr do
          log ""
          log "     Your version: #{your_version = Gem::Version.new(Ts3r::VERSION)}"

          # get current version
          logger.log_with_print do
            log "  Current version: "
            if @opts[:check_for_updates]
              require "net/http"
              log c("checking...", :blue)

              begin
                current_version = Gem::Version.new Net::HTTP.get_response(URI.parse(Ts3r::UPDATE_URL)).body.strip

                if current_version > your_version
                  status = c("#{current_version} (consider update)", :red)
                elsif current_version < your_version
                  status = c("#{current_version} (ahead, beta)", :green)
                else
                  status = c("#{current_version} (up2date)", :green)
                end
              rescue
                status = c("failed (#{$!.message})", :red)
              end

              logger.raw "#{"\b" * 11}#{" " * 11}#{"\b" * 11}", :print # reset cursor
              log status
            else
              log c("check disabled", :red)
            end
          end

          # more info
          log ""
          log "  Ts3r is brought to you by #{c "bmonkeys.net", :green}"
          log "  Contribute @ #{c "github.com/2called-chaos/ts3r", :cyan}"
          log "  Eat bananas every day!"
          log ""
        end
      end

      def dispatch_console
        establish_connection!
        o = Console.new(app: self, ts: @connection, store: {})
        def o.help
          app.log "Type " << app.c("help", :magenta) << app.c(" to show this help again.")
          app.log "Type " << app.c("exit", :magenta) << app.c(" to end the session.")
          app.log "Type " << app.c("exit!", :magenta) << app.c(" to terminate session (escape loop).")
          app.log "You have the following local variables: " << app.c("app, ts, store", :magenta)
          app.log "For example type: " << app.c("ts.version", :magenta) << app.c(" or ") << app.c("ts.serverlist", :magenta)
        end
        o.help
        o.pry(quiet: true)
      end

      def dispatch_index
        tasks = @config.get("ts3r.tasks") || {}
        if tasks.empty?
          binding.pry
          abort "No tasks defined, we would do nothing!"
        else
          establish_connection!
          log "Starting loop..."
          loop do
            tasks.each do |name, task|
              logger.ensure_prefix c("[#{name}]\t", :magenta) do
                task[self, @connection, @config.get("task_store.#{name}") || @config.set("task_store.#{name}", {})]
              end
            end
            sleep @config.get("ts3r.tick_sleep")
          end
        end
      end
    end
  end
end
