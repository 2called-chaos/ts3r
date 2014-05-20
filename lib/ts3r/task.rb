module Ts3r
  class Task
    attr_reader :app, :store, :ts, :async

    def initialize name, &callback
      @name = name
      @callback = callback
      @store = {}
    end

    def ts
      @app.connection
    end

    def gmm *messages
      messages = [*messages]
      ts.gm msg: "\\n#{messages.join("\\n")}".gsub(" ", "\\s")
    end

    def red_gm *messages
      messages = [*messages]
      ts.gm msg: "\\n[color=#cc0000]#{messages.join("\\n")}[/color]".gsub(" ", "\\s")
    end

    def gm_maintenance
      red_gm ["[b]Server will go down for maintenance in a few minutes, hold on tight![/b]"] * 3
    end

    def use_server id = 1
      ts.use(sid: id)[0]["msg"] == "ok" || raise("failed to use virtual server ##{id}")
    end

    def invoke app, async
      @app, @async = app, async
      catch :return do
        instance_eval(&@callback)
      end
    end

    def nick name = nil
      begin
        ts.clientupdate(client_nickname: name || app.config.get("ts3r.botname"))
      rescue Net::ReadTimeout
      end
    end

    def async &block
      Thread.new do
        catch :return do
          block.call
        end
      end.tap{|t| @async << t }
    end
  end
end
