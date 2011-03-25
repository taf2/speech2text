require 'rake/testtask'

desc "Default Task (Test project)"
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = false
end
