# Encoding: utf-8
module Heatmon
  class App
    module Helper
      extend ActiveSupport::Concern

      # @!group Helper

      def get_config file_or_project, file = nil
        cfile   = (file || file_or_project).to_s
        cfile  += ".rb" unless cfile.end_with?(".rb")
        project = file_or_project unless file.nil?
        Heatmon.root.join("config", [project, cfile].compact.join("/"))
      end

      def custom_configs project = "**", include_disabled = false
        r = Dir.glob("#{Heatmon.root.join("config", project.to_s, "*.rb")}")
        r.delete("#{get_config(:heatmon)}.rb")
        include_disabled ? r : r.reject(&@config.get("heatmon.configuration.ignore_file"))
      end

      def cfg_basedir file
        file.gsub(Heatmon.root.join("config").to_s, "%CFG%")
            .gsub(Heatmon.root.to_s, "%ROOT%")
      end

      def config_trace file, exception, severe = false
        trace = exception.backtrace[0..($heatmon_debug ? -1 : 2)]
        mfile = file.split(?/).last
        nl    = trace.select{|l| l[mfile] }.first.try(:match, /\A.*?:([0-9]+):.*?\z/i).try(:[], 1)
        l     = Thread.current[:logger]

        l.transaction do
          l.ensure_type(severe ? :severe : :warn) do
            l.log "An error occured while parsing config file #{file.magenta}" << " (near line #{nl || ??}):".red
            l.log "  #{exception.class}: #{exception.message}"
            trace.each {|line| l.log "    #{cfg_basedir(line)}" }
            l.log "  Run with `--debug' to get a full stack trace." unless $heatmon_debug
          end
        end

        if severe
          @shutdown = "cfg"
          mayexit 103
        end
      end

      def soft_trace exception, opts = {}
        opts = opts.reverse_merge(log: true, severe: false, handled: false, exit_code: nil, logger: nil)
        trace = exception.backtrace[0..($heatmon_debug ? -1 : 2)]
        l = opts.delete(:logger) || Thread.current[:logger]

        l.transaction do
          l.ensure_type(opts[:severe] ? :severe : :warn) do
            # print exception to console
            if opts[:severe]
              l.log "An unhandled exception caused the application to terminate:"
            else
              l.log "An #{"un" unless opts[:handled]}handled exception occured:"
            end
            l.log "  #{exception.class}: #{exception.message}"
            trace.each {|line| l.log "    #{cfg_basedir(line)}" }
          end
          l.log "  Run with `--debug' to get a full stack trace." unless $heatmon_debug

          # log to file
          if opts[:log]
            begin
              l.debug "  @TODO log exceptions to file"
              l.log "  This exception got logged to " << "%ROOT%/log/exceptions.log".magenta
            rescue
              l.severe "  SEVERE: Failed to log exception to " << "%ROOT%/log/exceptions.log".magenta
            end
          end
        end

        # terminate application
        if opts[:severe]
          @shutdown = "severe"
          mayexit opts[:exit_code] || exception.try(:exit_code) || 1
        end
      end

      def print_banner opts = {}
        opts = opts.reverse_merge(line: true, subline: true, logger: nil)
        l = opts.delete(:logger) || Thread.current[:logger]
        l.transaction do
          l.log '            _______  _______ _________ _______  _______  _         '
          l.log '  |\     /|(  ____ \(  ___  )\__   __/(       )(  ___  )( (    /|  '
          l.log '  | )   ( || (    \/| (   ) |   ) (   | () () || (   ) ||  \  ( |  '
          l.log '  | (___) || (__    | (___) |   | |   | || || || |   | ||   \ | |  '
          l.log '  |  ___  ||  __)   |  ___  |   | |   | |(_)| || |   | || (\ \) |  '
          l.log '  | (   ) || (      | (   ) |   | |   | |   | || |   | || | \   |  '
          l.log '  | )   ( || (____/\| )   ( |   | |   | )   ( || (___) || )  \  |  '
          l.log '  |/     \|(_______/|/     \|   )_(   |/     \|(_______)|/    )_)  '
          l.log dividing_line if opts[:line]
          l.log '             Temperature based monitoring with Ruby!               '.red if opts[:subline]
        end
      end

      def dividing_line color = :black
        '–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––'.colorize(color)
      end

      # define point where application or unsafe can safely exit when term signal is received
      def mayexit code = 0
        return true if !@shutdown
        return if !@tman
        if Thread.current == Thread.main
          if Thread.main[:concurrency_core_ready]
            @tman.spawn_shutdown_announcer
            @tman.broadcast_conds
            Thread.main[:ready_to_exit] = true
            @tman.wait_for_threads_to_exit
          end
          exit code
        end
        Thread.current.kill
      end

      # Mark application for termination.
      # This method is not thread safe in terms of keeping the correct signal.
      # It will shutdown under any circumstances.
      def shutdown! sig = "Shutting down"
        unless @shutdown
          @shutdown = "#{sig}"
        end
      end

      # @!endgroup
    end
  end
end
