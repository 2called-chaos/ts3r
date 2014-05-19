module Heatmon
  # Contains the singleton core for the Heatmon module.
  module Singleton
    extend ActiveSupport::Concern

    included do
      module_function :root, :app, :configure
    end

    # @return [String] Heatmon root directory
    def root
      ROOT
    end

    # @return [App] app instance
    def app *args
      created = !!!@app
      @app ||= App.new(*args)
      @app.init! if created
      @app
    end

    # Forward configure to the {#app app instance}
    def configure *args, &block
      app.config.setup(*args, &block)
    end
  end
end
