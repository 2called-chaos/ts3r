module Heatmon
  # Heatmon notification gateway base class.
  class Gateway
    class Email < Gateway
      def initialize address
        @address = address
      end
    end
  end
end
