module Heatmon
  # Heatmon configuration class for main and custom configurations.
  class Configuration
    # Require class files
    Banana.require_on self, %w[base responsible]

    # include stuff
    include Base
    include Responsible::DSL
  end
end
