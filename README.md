# MongoidRichCounterCache

## Installaion

Just include it in your project's `Gemfile` with Bundler:
```
gem 'mongoid_rich_counter_cache', :git => 'git://github.com/helloqidi/mongoid_rich_counter_cache.git'
```
then, run bundle:
```
$ bundle install
```

## Usage

###1. True field

First add a field to the document where you will be accessing the counter cache from.
```
class User
  include Mongoid::Document

  field :name,          :type=>String
  field :arts_count,    :type=>Integer,     :default=>0

  has_many :arts
end
```

Then in the referrenced document. Include `Mongoid::RichCounterCache`
```
class Art
  include Mongoid::Document
  include Mongoid::RichCounterCache

  field :title,     :type=>String
  field :published, :type=>Integer
  field :user_id,   :type=>String

  belongs_to    :user
  counter_cache :name => 'user', :field => 'arts_count',:if=>:published?

  def published?
    return true  if  self.published == 1
    return false
  end  
end
```


###2. Virtual field

First add methods to the document where you will be accessing the counter cache from.
```
class User
  include Mongoid::Document

  field :name,          :type=>String
  field :counter,       :type=>Hash,   :default=>{"message_count"=>0,"alert_count"=>0,"notice_count"=>0,"fans_count"=>0,"comment_count"=>0}

  def message_count_info
    return 0 if self.counter.blank?
    self.counter["message_count"] || 0
  end
  def message_count_info=(count)
    self.counter={} if self.counter.blank?
    self.counter["message_count"]=count
  end
end
```

Then in the referrenced document. Include `Mongoid::RichCounterCache`
```
class Message
  include Mongoid::Document
  include Mongoid::RichCounterCache

  field :content,           :type=>String
  field :from_user_id,      :type=>String
  field :to_user_id,        :type=>String

  belongs_to :from_user, :class_name=>"User",:foreign_key=>"from_user_id"
  belongs_to :to_user,   :class_name=>"User",:foreign_key=>"to_user_id"

  counter_cache :name => 'to_user', :field => 'message_count_info',:destroy=>false
end
```


###3. Change counter cache without Mongoid's 'destroy' and 'create' methods.

First add a field to the document where you will be accessing the counter cache from.
```
class User
  include Mongoid::Document

  field :name,          :type=>String
  field :arts_count,    :type=>Integer,     :default=>0

  has_many :arts
end
```

Then in the referrenced document. Include `Mongoid::RichCounterCache`
```
class Art
  include Mongoid::Document
  include Mongoid::RichCounterCache

  field :title,     :type=>String
  field :published, :type=>Integer
  field :user_id,   :type=>String
  field :deleted,   :type=>Integer

  belongs_to    :user
  counter_cache :name => 'user', :field => 'arts_count'

  def mark_delete
    if self.update_attribute(:deleted,1)
      #this is the api method
      counter_cache_delete
      return true
    else
      return false
    end  
  end

  def re_mark_delete
    if self.update_attribute(:deleted,0)
      #this is the api method
      re_counter_cache_delete
      return true
    else
      return false
    end
  end

end
```

When deleting one art's counter_cache
```
  art=Art.first
  art.counter_cache_delete
```

When undeleting one art's counter_cache
```
  art=Art.first
  art.re_counter_cache_delete
```
