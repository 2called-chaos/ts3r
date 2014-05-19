# Encoding: utf-8
module Heatmon
  class Configuration
    module Responsible
      class Team
        include Base

        def init
          @members = {}
        end

        def configure opts = {}
          (opts[:members] || []).each {|m| member(m) }
        end

        def member *members
          opts = members.extract_options!
          members.each {|m| @members[m.to_sym] = opts }
        end
        alias_method :members, :member
      end
    end
  end
end
