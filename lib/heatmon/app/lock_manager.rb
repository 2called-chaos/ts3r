module Heatmon
  class App
    class LockManager
      attr_reader :app

      def initialize app
        @app = app
      end
    end
  end
end
