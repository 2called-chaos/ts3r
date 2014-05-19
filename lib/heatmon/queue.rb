module Heatmon
  class Queue
    def initialize
      @que = []
      @que.taint # enable tainted communication
      @num_waiting = 0
      self.taint
      @mutex = Mutex.new
      @cond = ConditionVariable.new
    end

    def push(obj)
      Thread.handle_interrupt(StandardError => :on_blocking) do
        @mutex.synchronize do
          @que.push obj
          @cond.signal
        end
      end
    end
    alias << push
    alias enq push

    def enq_ary(array)
      Thread.handle_interrupt(StandardError => :on_blocking) do
        @mutex.synchronize do
          @que = @que + array
          @cond.signal
        end
      end
    end

    def unshift(obj)
      Thread.handle_interrupt(StandardError => :on_blocking) do
        @mutex.synchronize do
          @que.unshift obj
          @cond.signal
        end
      end
    end
    alias prepend unshift

    def pop(non_block=false)
      Thread.handle_interrupt(StandardError => :on_blocking) do
        @mutex.synchronize do
          while true
            if @que.empty?
              if non_block
                raise ThreadError, "queue empty"
              else
                begin
                  @num_waiting += 1
                  @cond.wait @mutex
                ensure
                  @num_waiting -= 1
                end
              end
            else
              return @que.shift
            end
          end
        end
      end
    end
    alias shift pop
    alias deq pop

    def empty?
      @que.empty?
    end

    def clear
      @que.clear
    end

    def length
      @que.length
    end
    alias size length
    alias count length

    def num_waiting
      @num_waiting
    end
  end
end
