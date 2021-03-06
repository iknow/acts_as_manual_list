# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'acts_as_manual_list/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'acts_as_manual_list'
  s.version     = ActsAsManualList::VERSION
  s.authors     = ['iKnow Team']
  s.email       = ['dev@iknow.jp']
  s.homepage    = ''
  s.summary     = 'Barebones acts_as_list'
  s.description = ''
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'activerecord', '> 5.0'
  s.add_dependency 'activesupport', '> 5.0'
  s.add_dependency 'lazily', '~> 0.2.1'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'sqlite3'
end
