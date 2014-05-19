# Encoding: utf-8
module Heatmon
  class App
    module Dispatch
      extend ActiveSupport::Concern

      # @!group Dispatch

      def dispatch env, argv
        @env, @argv = env, argv
        init_parameters!(argv)

        # determine action
        action = case true
          when @opts[:testloop]        then :testloop
          when @opts[:help]            then :help
          when @opts[:version]         then :info
          when @opts[:configtest].any? then :configtest
          else :daemon
          # else abort("Unknown or no action provided (run with --help)", 1)
        end

        # dispatching
        begin
          logger.ensure_prefix("[DISPATCH] ".magenta) { debug("Dispatching action #{action.to_s.magenta}#{"...".blue}") }
          tman.spawn :dispatch do
            exclusive_logger
            send("dispatch_#{action}")
          end.join
        rescue StandardError => e
          logger.ensure_prefix("[DISPATCH] ".magenta) { debug "Started error handling for failed action #{action.to_s.magenta}" }
          soft_trace(e, severe: true, exit_code: 101)
        end
      ensure
        finalize
      end

      def finalize code = 0
        @shutdown = true
        mayexit(code)
      end

      def dispatch_testloop
        until @shutdown do
          log "blub"
          debug "foo"
          sleep 1
        end
        debug "stopping testloop..."
        sleep 3
        debug "testloop stopped"
      end

      def dispatch_help
        logger.raw @optparse.to_s
      end

      def dispatch_info
        l = Thread.current[:logger]
        l.channel.exclusive do
          l.log_without_timestr do
            print_banner
            log ""
            log "     Your version: #{your_version = Gem::Version.new(Heatmon::VERSION)}"

            # get current version
            l.log_with_print do
              log "  Current version: "
              if @config.get("heatmon.calling_home.check_version")
                log "checking...".blue

                begin
                  current_version = Gem::Version.new Net::HTTP.get_response(URI.parse(Heatmon::UPDATE_URL)).body.strip

                  if current_version > your_version
                    status = "#{current_version} (consider update)".red
                  elsif current_version < your_version
                    status = "#{current_version} (ahead, beta)".green
                  else
                    status = "#{current_version} (up2date)".green
                  end
                rescue
                  status = "failed (#{$!.message})".red
                end

                l.raw "#{"\b" * 11}#{" " * 11}#{"\b" * 11}", :print # reset cursor
                log status
              else
                log "check disabled".red
              end
            end

            # more info
            log ""
            log "  Heatmon is brought to you by #{"bmonkeys.net".green}"
            log "  Contribute @ #{"github.com/bmonkeys/heatmon".cyan}"
            log "  Eat bananas every day!"
            log ""
          end
        end
      end

      def dispatch_configtest
        errors = 0
        l = Thread.current[:logger]

        @opts[:configtest].each do |cfg|
          l.ensure_prefix("[CCONF] ".magenta) do
            file = get_config(cfg)
            bfile = cfg_basedir(file.to_s)

            log "Processing " << bfile.magenta << "...".yellow
            l.prefix += "  "

            begin
              load file
            rescue ScriptError, StandardError
              errors += 1
              if $!.message[/cannot load such file/]
                warn "not found".red
              else
                config_trace(bfile, $!)
              end
            end
          end
        end

        l.raw(dividing_line)
        if errors > 0
          warn "#{errors} file(s) are not valid!"
        else
          log "All files OK!".green
        end
      end

      def dispatch_daemon
        print_banner
        init_daemon!
        abort "So far so good!"
      end

      # @!endgroup
    end
  end
end
