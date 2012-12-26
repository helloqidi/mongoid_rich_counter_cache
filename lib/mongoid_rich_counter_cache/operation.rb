# encoding: utf-8
module MongoidRichCounterCache

  class Operation
    include ClassUtilMixin

    #类常量
    @@ATTRIBUTES = [
      #实例对象
      :document,
      #操作类型:create/destroy
      :operate,
      #关联表名
      :name,
      #关联字段
      :counter_field,
      #是否执行的判断
      :if_judge_m,
      #是否执行删除的判断
      :if_destroy
    ]
   
    #方法
    attr_accessor *@@ATTRIBUTES

    def execute
      if self.operate=="create"
        self.core(1)
      else
        return unless self.if_destroy
        self.core(-1)
      end
    end#execute

    #执行加/减操作
    #减操作不能出现负数
    def core(num)
      if (self.if_judge_m==nil) || (self.if_judge_m && self.document.send(self.if_judge_m))
        relation = self.document.send(self.name)
        if relation
          if relation.class.fields.keys.include?(self.counter_field)
            relation.inc(self.counter_field.to_s, num) unless num==-1 && relation.send(self.counter_field.to_s).to_i<=0
          else
            #针对虚拟属性
            hash={self.counter_field.to_s=>relation.send(self.counter_field)+1}
            relation.update_attributes(hash) unless num==-1 && relation.send(self.counter_field.to_s).to_i<=0
          end
        end
      end    
    end#core

  end#Operation module
end
