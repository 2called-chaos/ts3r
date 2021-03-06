# Encoding: utf-8
module Ts3r
  class Application
    class Configuration
      attr_reader :store

      def self.attr_assigner *names
        opts = names.extract_options!.reverse_merge(cast: nil)
        names.each do |n|
          define_method(n) {|v| set(n, opts[:cast] ? v.send(opts[:cast]) : v) }
        end
      end

      def initialize *args, &block
        @current_store = @store = {}
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

      def setup namespace = :ts3r, &block
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
    end
  end
end
