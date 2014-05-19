# Encoding: utf-8
module Heatmon
  class Configuration
    module Base
      extend ActiveSupport::Concern

      included do
        attr_reader :store, :target
      end

      def initialize target, *args, &block
        @target = target
        @current_store = @store = {}
        if respond_to?(:init)
          Banana::Kernel.__call_method_like_proc method(:init), *args
        end
        setup(nil, &block) if block
      end

      def group name, &block
        old_store, @current_store = @current_store, @current_store[name.to_sym] ||= {}
        block.call(@current_store) if block
        @current_store = old_store
      end

      def set name, value = nil, &block
        if block
          @current_store[name.to_sym] = block.call
        else
          @current_store[name.to_sym] = value
        end
      end

      def setup namespace = :heatmon, &block
        old_store, @current_store = @current_store, namespace.nil? ? @store : (@current_store[namespace.to_sym] ||= {})
        instance_exec(@current_store, &block)
        @current_store = old_store
      end

      def get address, default = nil
        address.split(".").inject(@store) {|cfg, sub| cfg = cfg.try(:[], sub.to_sym) } || default
      end

      def [] key
        @store[key]
      end

      module ClassMethods
        def attr_assigner *names
          opts = names.extract_options!.reverse_merge(cast: nil)
          names.each do |n|
            define_method(n) {|v| set(n, opts[:cast] ? v.send(opts[:cast]) : v) }
          end
        end
      end
    end
  end
end
