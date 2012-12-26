# encoding: utf-8

#载入相对路径的文件
def require_local(suffix)
  require(File.expand_path(File.join(File.dirname(__FILE__), suffix)))
end

require_local('mongoid_rich_counter_cache/version')
require_local('mongoid_rich_counter_cache/mongoid_rich_counter_cache')
require_local('mongoid_rich_counter_cache/core')
require_local('mongoid_rich_counter_cache/operation')
