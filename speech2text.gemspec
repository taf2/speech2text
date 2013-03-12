$:.unshift File.expand_path(File.dirname(__FILE__) + "/lib")
require "speech/version"

Gem::Specification.new do |s|
  s.name           = "speech2text"
  s.authors        = ["Todd A. Fisher"]
  s.email          = "todd.fisher@gmail.com"
  s.version        = Speech::Info::VERSION
  s.homepage       = "https://github.com/taf2/speech2text"
  s.summary        = "Speech to Text Library"
  s.description    = "Super powers of Google wrapped in a nice Ruby interface"
  s.files          = Dir["{lib,bin,test}/**/*", "Rakefile", "README.rdoc", "*.gemspec"]
  s.executables    = %w(speech2text)

  s.add_dependency "curb"
  s.add_dependency "json"
  s.add_dependency "uuid"
end
