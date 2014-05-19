# Encoding: utf-8
module Heatmon
  class Configuration
    module Responsible
      module DSL
        extend ActiveSupport::Concern

        included do

        end

        def responsibles
          @responsibles ||= {}
        end

        def responsible identifier, &block
          responsibles[identifier] = Person.new(identifier, &block)
        end

        def team *identifiers, &block
          opts = identifiers.extract_options!
          identifiers.each do |id|
            responsibles[id] ||= Team.new(id)
            responsibles[id].configure(opts, &block)
          end
        end
      end
    end
  end
end
