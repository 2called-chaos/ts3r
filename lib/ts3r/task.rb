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

    def use_server id
      ts.use(sid: id)[0]["msg"] == "ok" || raise("failed to use virtual server ##{id}")
    end

    def invoke app, async
      @app, @async = app, async
      catch :return do
        instance_eval(&@callback)
      end
    end

    def nick name
      ts.clientupdate client_nickname: name
    end

    def async &block
      Thread.new(&block).tap{|t| @async << t }
    end
  end
end
