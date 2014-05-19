module Heatmon
  module Parser
    module Support
      def string_to_lines str
        str.split("\n").reject(&:blank?).map(&:strip)
      end

      def first_word str
        str.split.first
      end
    end
  end
end
