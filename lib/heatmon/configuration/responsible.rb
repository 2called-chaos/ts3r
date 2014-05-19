module Heatmon
  class Configuration
    module Responsible
      # Require class files
      Banana.require_on self, %w[dsl person team]
    end
  end
end
