
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/eks_in_a_box'

Gem::Specification.new do |spec|
  spec.name          = "eks-in-a-box"
  spec.version       = EksInABox::VERSION
  spec.authors       = ["Timothy Mukaibo"]
  spec.email         = ["timothy.mukaibo@rea-group.com"]

  spec.summary       = %q{The easy way to spin up an EKS cluster at REA}
  spec.description   = %q{Creates EKS cluster and configures components in Kubernetes to make the cluster useful}
  spec.homepage      = 'https://git.realestate.com.au/timothy-mukaibo/eks-in-a-box'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = 'https://rubygems.delivery.realestate.com.au'

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = 'https://git.realestate.com.au/timothy-mukaibo/eks-in-a-box'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
