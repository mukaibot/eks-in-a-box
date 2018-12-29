require "rake/testtask"
require 'geminabox-release'

Dir.glob('lib/tasks/**/*.rake').each(&method(:load))

GeminaboxRelease.patch(:host => "https://rubygems.delivery.realestate.com.au")

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc 'Run the E2E tests (these take a LONG time)'
task :e2e_tests do
  begin
    Rake::Task['setup'].invoke
    Rake::Task['test'].invoke
  ensure
    Rake::Task['teardown'].invoke
  end
end

task :default => :test
