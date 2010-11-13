require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
  s.name = "hardlinker"
  s.version = "0.0.1"
  s.author = "Roger Jungemann"
  s.email = "roger@thefifthcircuit.com"
  s.homepage = "http://github.com/thefifthcircuit/hardlinker"
  s.platform = Gem::Platform::RUBY
  s.summary = "A simplified syntax for creating wiki links."
  s.description = s.summary
  s.files = FileList["{bin,lib,vendor}/**/*"].to_a
  s.require_path = "lib"
  #s.autorequire = "name"
  #s.test_files = FileList["turnstile_spec.rb"].to_a
  s.has_rdoc = false
  #s.extra_rdoc_files = ["LICENSE.txt, README.txt"]
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end