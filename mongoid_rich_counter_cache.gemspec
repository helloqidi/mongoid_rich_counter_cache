# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid_rich_counter_cache/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_rich_counter_cache"
  s.version     = MongoidRichCounterCache::VERSION
  s.authors     = ["helloqidi"]
  s.email       = ["helloqidi@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{mongoid_rich_counter_cache}
  s.description = %q{mongoid_rich_counter_cache}

  s.rubyforge_project = "mongoid_rich_counter_cache"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
