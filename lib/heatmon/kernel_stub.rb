module Heatmon
  module KernelStub
    def exclusive
      yield if block_given?
    end

    def enq_ary array
      array.each {|a| send(*a) }
    end

    def priority msg, method = :puts
      send(method, msg)
    end
    alias_method :queue, :priority
  end
end
