module Heatmon
  # Heatmon application main class. Includes several subclasses and modules.
  #
  # Possible exit codes
  #     - 0   => success
  #     - 1   => something went wrong (generic)
  #     - 10  => generic input error (malformed application invokation)
  #     - 101 => severe dispatch error
  #     - 102 => severe lock error
  #     - 103 => severe configuration error
  #     - 104 => severe scheduler error
  #     - 125 => development/test
  class App
    # Require stdlib dependencies
    require "optparse"
    require "thread"
    require "monitor"
    require "net/http"

    # Require class files
    Banana.require_on self, %w[helper selftest thread_manager lock_manager log_spool setup dispatch]

    # include stuff
    include Logger::DSL
    include Helper
    include Selftest
    include Setup
    include Dispatch
  end
end

# load configurations
# compile configurations

#----- Setup for daemon
# assign checks to queues
# initial check scheduling
# perform config selfcheck
# init handlers and workers
#----- SETUP FINISHED
# start workers

