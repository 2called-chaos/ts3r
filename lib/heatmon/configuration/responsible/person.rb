# Encoding: utf-8
module Heatmon
  class Configuration
    module Responsible
      class Person
        include Base

        attr_assigner :name
        attr_assigner :fallback, cast: :to_sym

        def init
          @gateways = {}
        end

        def register_gateway name, *args, &block
          if name.is_a?(Array)
            klass = name[1]
            name  = name[0]
          else
            klass = Gateway.const_get(name.to_s.camelize)
          end
          @gateways[name] = klass.new(*args, &block)
        end

        def email *args
          register_gateway :email, *args
        end

        def xmpp *args
          register_gateway :xmpp, *args
        end
      end
    end
  end
end
