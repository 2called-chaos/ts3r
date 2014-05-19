module Heatmon
  # Collection of various parsers to be used in tests and/or tasks.
  module Parser
    Banana.require_on(self, %w[
      support
      unix/proc/mdstat
    ])
  end
end
