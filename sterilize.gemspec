# encoding: UTF-8

$:.push File.expand_path("../lib", __FILE__)
require "sterilize/version"

Gem::Specification.new do |s|
  s.name        = "sterilize"
  s.version     = Sterilize::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patrick Hogan"]
  s.email       = ["pbhogan@gmail.com"]
  s.homepage    = "https://github.com/pbhogan/sterilize"
  s.summary     = %q{Sterilize your strings! Transliterate, generate slugs, smart format, strip tags, encode/decode entities and more.}
  s.description = s.summary

  s.rubyforge_project = "sterilize"

  # s.add_dependency("nokogiri")

  # s.add_development_dependency("autotest")
  # s.add_development_dependency("mynyml-redgreen")
  # s.add_development_dependency("awesome_print")
  # s.add_development_dependency("rake")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths  = ["lib"]
end
