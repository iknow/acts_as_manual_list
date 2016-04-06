$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_manual_list/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_manual_list"
  s.version     = ActsAsManualList::VERSION
  s.authors     = ["Andrew Childs"]
  s.email       = ["andrew.childs@bibo.com.ph"]
  s.homepage    = ""
  s.summary     = "Barebones acts_as_list"
  s.description = ""
  s.license     = "Proprietary"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "activerecord"
  s.add_dependency "activesupport"
  s.add_dependency "lazily"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  s.add_development_dependency "byebug"
end
