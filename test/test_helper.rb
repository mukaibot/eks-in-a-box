$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'yaml'
require 'json'
require 'open3'
require 'minitest/autorun'
require 'minitest/hooks/test'
require 'custom_assertions'

ROOT = File.expand_path(File.join(__dir__, '..'))

class Test < Minitest::Test
  include Minitest::Hooks
  include CustomAssertions
end

class ParallelTest < Test
  parallelize_me!
end
