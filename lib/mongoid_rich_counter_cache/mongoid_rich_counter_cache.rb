# encoding: utf-8
module Mongoid
  module RichCounterCache
    
    def self.included(base)
      base.send :extend, ClassMethods
      #初始化类变量
      base.counter_cache_groups=[]
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      
      #对counter_cache记录的表和字段进行递减操作,减操作不能出现负数
      #可用于非物理删除的情况
      def counter_cache_delete
        self.class.counter_cache_groups.each do |group|
          name=group[:name]
          counter_field=group[:field]
          if_judge_m=group[:if]
          if_destroy=group[:destroy]
          
          operation=MongoidRichCounterCache::Operation.new({:document=>self,
                                                           :operate=>"destroy",
                                                           :name=>name,
                                                           :field=>counter_field,
                                                           :if=>if_judge_m,
                                                           :destroy=>if_destroy}
                                                          )
          operation.execute
        end#each
      end#counter_cache_delete

      #对counter_cache记录的表和字段进行递增操作
      #可用于撤销非物理删除的情况
      def re_counter_cache_delete
        self.class.counter_cache_groups.each do |group|
          name=group[:name]
          counter_field=group[:field]
          if_judge_m=group[:if]
          if_destroy=group[:destroy]

          operation=MongoidRichCounterCache::Operation.new({:document=>self,
                                                           :operate=>"create",
                                                           :name=>name,
                                                           :field=>counter_field,
                                                           :if=>if_judge_m,
                                                           :destroy=>if_destroy}
                                                          )
          operation.execute
        end#each
      end#re_counter_cache_delete    
    end#InstanceMethods module

    module ClassMethods
      #声明类变量
      def counter_cache_groups
        @counter_cache_groups
      end
      def counter_cache_groups=(value)
        @counter_cache_groups=value
      end

      def counter_cache(options)
        name = options[:name]
        counter_field = options[:field]
        #获得if指定的方法 :if=>:stuff?
        if_judge_m=options[:if]
        #是否执行删除方法 :destroy=>false
        if_destroy=options[:destroy]

        counter_cache_groups<<{:name=>name,:field=>counter_field,:if=>if_judge_m,:destroy=>if_destroy}

        after_create do |document|
          operation=MongoidRichCounterCache::Operation.new({:document=>document,
                                                           :operate=>"create",
                                                           :name=>name,
                                                           :field=>counter_field,
                                                           :if=>if_judge_m,
                                                           :destroy=>if_destroy}
                                                          )
          operation.execute
        end#after_create

        after_destroy do |document|
          operation=MongoidRichCounterCache::Operation.new({:document=>document,
                                                           :operate=>"destroy",
                                                           :name=>name,
                                                           :field=>counter_field,
                                                           :if=>if_judge_m,
                                                           :destroy=>if_destroy}
                                                          )
          operation.execute
        end#after_destroy

      end#counter_cache
    end#ClassMethods module

  end
end
