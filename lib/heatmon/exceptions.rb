module Heatmon
  # Heatmon exceptions
  module Error
    class GenericError < Exception
      attr_accessor :exit_code

      def initialize *args
        @exit_code ||= 1
        if args[2].is_a?(Integer)
          @exit_code = args.delete_at(2)
        elsif args[3].is_a?(Integer)
          @exit_code = args.delete_at(3)
        end
        super(args)
      end
    end

    class LockError < GenericError
      def initialize *args
        @exit_code = 102
        super
      end
    end

    class ParseError < Exception ; end
    class HaltingError < Exception ; end
  end
end
