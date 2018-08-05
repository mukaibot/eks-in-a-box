require 'json'
require 'logger'
require 'open3'
require 'eks_config'

class VpcCreator
  attr_reader :logger, :cluster_name, :role_arn, :vpc_id, :eks_config

  ACCESS_PARAMS = 'access_params.json'

  def initialize
    @region             = 'us-west-2'
    @logger             = Logger.new(STDOUT)
    @availability_zone1 = @region + 'a'
    @availability_zone2 = @region + 'b'
    @eks_config         = EksConfig.new
  end

  def call
    get_cluster_name
    write_vpc_params
    create_vpc
    self
  end

  def access_stack_name
    @cluster_name + "-access"
  end

  def vpc_name
    @cluster_name + "-vpc"
  end

  private

  def access_params(vpc_id)
    [
      {
        "ParameterKey"   => "ClusterName",
        "ParameterValue" => @cluster_name,
      },
      {
        "ParameterKey"   => "VpcId",
        "ParameterValue" => vpc_id,
      }
    ]
  end

  def create_command(vpc_name)
    [
      "aws",
      "cloudformation",
      "create-stack",
      "--stack-name",
      vpc_name,
      "--template-body file://deps/rea-vpc/vpc.json",
      "--parameters file://vpc_params.json",
      "--region",
      @region
    ].join(" ")
  end

  def create_access_command(stack_name)
    [
      "aws",
      "cloudformation",
      "create-stack",
      "--stack-name",
      stack_name,
      "--template-body file://templates/access.yaml",
      "--parameters file://access_params.json",
      "--region",
      @region,
      "--capabilities",
      "CAPABILITY_NAMED_IAM"
    ].join(" ")
  end

  # Todo - refactor me!
  def create_vpc
    logger.info "Ensuring VPC stack #{vpc_name}"
    swallow_it, status = Open3.capture2e(create_command(vpc_name))
    vpc_wait, status = Open3.capture2e(wait_command(vpc_name))

    describe_stack        = "aws cloudformation describe-stacks --stack-name #{vpc_name}"
    stack, status = Open3.capture2e(describe_stack)

    vpc_stack = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
    @vpc_id = output_value(vpc_stack, "Vpc")

    dump_vpc_params(vpc_id)
    logger.info "Ensuring VPC access stack #{access_stack_name}"
    access_stack, status = Open3.capture2e(create_access_command(access_stack_name))
    Open3.capture2e(wait_command(access_stack_name))
    describe_access_stack = "aws cloudformation describe-stacks --stack-name #{access_stack_name}"
    stack, status = Open3.capture2e(describe_access_stack)
    stackputs = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
    @eks_config.role_arn = output_value(stackputs, "RoleArn")
    @eks_config.security_group_id = output_value(stackputs, "SecurityGroup")
    @eks_config.subnet_ids = %w(SubnetPublic1 SubnetPublic2 SubnetPrivate1 SubnetPrivate2).map do |key|
      output_value(vpc_stack, key)
    end
    @eks_config.cluster_name = @cluster_name
    @eks_config.vpc_id = vpc_id

    logger.info "#{@cluster_name} IAM role is #{@eks_config.role_arn}"
    logger.info "VPC #{vpc_id} ready"
  end

  # Todo - extract this to bin/eks-box or similar
  def get_cluster_name
    logger.info "What should we call your cluster? Short DNS name is recommended, a-z, dashes and dots are allowed. EG: my-cluster"
    @cluster_name = gets.chomp

    "Need a valid cluster name" if @cluster_name.nil? || @cluster_name.empty?
  end

  def dump_vpc_params(vpc_id)
    File.open(ACCESS_PARAMS, 'w') do |f|
      f.write(access_params(vpc_id).to_json)
    end
  end

  def output_value(outputs, key)
    outputs.find { |out| out.fetch("OutputKey") == key }.fetch("OutputValue")
  end

  def wait_command(stack)
    [
      "aws",
      "cloudformation",
      "wait",
      "stack-create-complete",
      "--stack-name",
      stack,
      "--region",
      @region
    ].join(" ")
  end

  def write_vpc_params
    File.open('vpc_params.json', 'w') { |f| f.puts vpc_params.to_json }
  end

  def vpc_params
    [
      {
        "ParameterKey"   => "AvailabilityZone1",
        "ParameterValue" => @availability_zone1,
      },
      {
        "ParameterKey"   => "AvailabilityZone2",
        "ParameterValue" => @availability_zone2,
      },
      {
        "ParameterKey"   => "DomainName",
        "ParameterValue" => @cluster_name,
      }
    ]
  end
end
