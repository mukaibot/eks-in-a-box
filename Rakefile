require "rake/testtask"
require 'geminabox-release'

GeminaboxRelease.patch(:host => "https://rubygems.delivery.realestate.com.au")

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
