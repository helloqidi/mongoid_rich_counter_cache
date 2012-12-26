# encoding: utf-8
module Lakala
  # Core
  module ClassUtilMixin

    def self.included(base) 
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
    end
    
    module InstanceMethods
      def initialize(params = {})
        others = {}
        params.each do |key,val|
          if self.respond_to? key
            self.send("#{key}=", val)
          else
            others[key] = val
          end
        end
        self.send("#{:other_attrs}=", others) if self.respond_to? :other_attrs and others.size > 0
        self.send(:init) if self.respond_to? :init
      end        
    end#InstanceMethods module

  end#ClassUtilMixin module
end
