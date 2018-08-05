require 'json'
require 'logger'
require 'open3'

class EksConfigurationWriter
  attr_reader :logger, :vpc_name
  CONFIG = "eks-box-config.yml"

  def initialize(vpc_name, cluster_name)
    @logger       = Logger.new(STDOUT)
    @vpc_name     = vpc_name
    @cluster_name = cluster_name
  end

  def call

    describe_stack = "aws cloudformation describe-stacks --stack-name #{vpc_name}"

    stack, stderr, status = Open3.capture3(describe_stack)

    stackputs = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
  end

  private

  def config_hash(vpc_outputs, access_outputs)
    {
      vpc_id:  output_value(vpc_outputs, "Vpc"),
      role_id: output_value(access_outputs, "RoleArn")
    }
  end

  def output_value(outputs, key)
    outputs.find { |out| out.fetch("OutputKey") == key }.fetch("OutputValue")
  end
end
