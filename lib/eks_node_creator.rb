require 'logger'
require 'json'
require 'open3'
require 'erb'

class EksNodeCreator
  attr_reader :config, :logger

  NODE_PARAMS_FILE = "node_params.json"
  TEMPLATE = "templates/node-auth-configmap.yaml.erb"
  NODE_POLICY_FILE = "node_policy.yaml"

  def initialize(config)
    @logger = Logger.new(STDOUT)
    @config = config
    @node_type = "t2.small"
  end

  def call
    logger.info "Ensuring EKS node stack #{stack_name}"
    write_params
    node_stack, status = Open3.capture2e(create_nodes_command)
    vpc_wait, status   = Open3.capture2e(wait_command)
    if status.exitstatus == 0
      apply_node_config_map
      logger.info "Nodes created successfully"
    else
      logger.error node_stack
      exit 1
    end
  end

  private

  def apply_node_config_map
    describe_nodes = [
      "aws",
      "cloudformation",
      "describe-stacks",
      "--stack-name",
      stack_name
    ].join(" ")

    stackputs, status = Open3.capture2e(describe_nodes)
    @node_role_arn = JSON.parse(stackputs).fetch("Stacks").first.fetch("Outputs").find { |output| output.fetch("OutputKey") == "NodeInstanceRole" }.fetch("OutputValue")
    File.open(NODE_POLICY_FILE, 'w') {|f| f.write ERB.new(File.read(TEMPLATE)).result(binding) }
    apply_command = [
      "kubectl",
      "apply",
      "-f",
      NODE_POLICY_FILE
    ].join(" ")

    Open3.capture2e(apply_command) { |stdouterr| logger.debug stdouterr }
  end

  def create_nodes_command
    [
      "aws",
      "cloudformation",
      "create-stack",
      "--stack-name",
      stack_name,
      "--template-body file://templates/amazon-eks-nodegroup.yaml",
      "--parameters file://#{NODE_PARAMS_FILE}",
      "--region",
      config.region,
      "--capabilities",
      "CAPABILITY_NAMED_IAM"
    ].join(" ")
  end

  def node_image
    case config.region
    when "us-west-2"
      "ami-73a6e20b"
    when "us-east-1"
      "ami-dea4d5a1"
    else
      abort "Unsupported region #{config.region}"
    end
  end

  def params
    {
      "KeyName" => config.cluster_name,
      "NodeImageId" => node_image,
      "NodeInstanceType" => @node_type,
      "ClusterName" => config.cluster_name,
      "NodeGroupName" => stack_name,
      "ClusterControlPlaneSecurityGroup" => config.security_group_id,
      "VpcId" => config.vpc_id,
      "Subnets" => config.private_subnets.join(",")
    }.map { |k,v| { "ParameterKey" => k, "ParameterValue" => v }}
  end

  def stack_name
    "#{config.cluster_name}-nodes"
  end

  def wait_command
    [
      "aws",
      "cloudformation",
      "wait",
      "stack-create-complete",
      "--stack-name",
      stack_name,
      "--region",
      config.region
    ].join(" ")
  end

  def write_params
    File.open(NODE_PARAMS_FILE, 'w') { |f| f.write params.to_json }
  end
end
