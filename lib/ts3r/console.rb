# Encoding: utf-8
module Ts3r
  class Console < Task
    def help
      app.log "Type " << app.c("help", :magenta) << app.c(" to show this help again.")
      app.log "Type " << app.c("exit", :magenta) << app.c(" to end the session.")
      app.log "Type " << app.c("exit!", :magenta) << app.c(" to terminate session (escape loop).")
      app.log "You have the following local variables: " << app.c("app, ts, store", :magenta)
      app.log "For example type: " << app.c("ts.version", :magenta) << app.c(" or ") << app.c("ts.serverlist", :magenta)
    end
  end
end
