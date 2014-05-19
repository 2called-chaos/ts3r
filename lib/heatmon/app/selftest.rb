module Heatmon
  class App
    module Selftest
      extend ActiveSupport::Concern

      # @!group Selftest

      def perform_selftest
        exclusive_logger do |l|
          l.debug "performing selftest..."
          l.transaction do
            l.ensure_prefix "[SELFTEST] ".magenta do
              # whatever makes sense to check
            end
          end
          l.debug "selftest completed"
        end
      end

      # @!endgroup
    end
  end
end
