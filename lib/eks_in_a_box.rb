module EksInABox
  VERSION = "1.0.#{ENV.fetch('BUILDKITE_BUILD_NUMBER', 'dev')}".freeze
end
