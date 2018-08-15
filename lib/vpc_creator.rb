require 'json'
require 'logger'
require 'open3'
require 'eks_config'

class VpcCreator
  attr_reader :logger, :cluster_name, :role_arn, :vpc_id, :eks_config

  ACCESS_PARAMS = 'access_params.json'

  def initialize(cluster_name)
    @cluster_name       = cluster_name
    @region             = 'us-east-1'
    @logger             = Logger.new(STDOUT)
    @availability_zone1 = @region + 'a'
    @availability_zone2 = @region + 'b'
    @eks_config         = EksConfig.new
  end

  def call
    write_vpc_params
    write_nat_params
    create_vpc
    self
  end

  def access_stack_name
    @cluster_name + "-access"
  end

  def bastion_stack_name
    vpc_name + "-bastion"
  end

  def vpc_name
    @cluster_name + "-vpc"
  end

  def vpc_nat_name
    vpc_name + "-nat"
  end

  private

  def rea_as_role
    ENV.fetch("AWS_ROLE_ARN")
  end

  def access_params(vpc_id)
    [
      {
        "ParameterKey"   => "AllowAccessFromIAMRole",
        "ParameterValue" => rea_as_role,
      },
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

  def create_bastion_command
    [
      "aws",
      "cloudformation",
      "create-stack",
      "--stack-name",
      bastion_stack_name,
      "--template-body file://templates/bastion.yaml",
      "--parameters file://bastion_params.json",
      "--region",
      @region
    ].join(" ")
  end

  def create_nat_command
    [
      "aws",
      "cloudformation",
      "create-stack",
      "--stack-name",
      vpc_nat_name,
      "--template-body file://deps/rea-vpc/nat.json",
      "--parameters file://nat_params.json",
      "--region",
      @region
    ].join(" ")
  end

  # Todo - refactor me!
  def create_vpc
    logger.info "Ensuring VPC stack #{vpc_name}"
    swallow_it, status = Open3.capture2e(create_command(vpc_name))
    vpc_wait, status   = Open3.capture2e(wait_command(vpc_name))
    logger.info "Ensuring VPC NAT stack #{vpc_nat_name}"
    add_nat, status = Open3.capture2e(create_nat_command)
    nat_wait, status   = Open3.capture2e(wait_command(vpc_nat_name))

    describe_stack = "aws cloudformation describe-stacks --stack-name #{vpc_name}"
    stack, status  = Open3.capture2e(describe_stack)

    vpc_stack = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
    @vpc_id   = output_value(vpc_stack, "Vpc")

    dump_vpc_params(vpc_id)
    logger.info "Ensuring VPC access stack #{access_stack_name}"
    access_stack, status = Open3.capture2e(create_access_command(access_stack_name))
    Open3.capture2e(wait_command(access_stack_name))
    describe_access_stack         = "aws cloudformation describe-stacks --stack-name #{access_stack_name}"
    stack, status                 = Open3.capture2e(describe_access_stack)
    stackputs                     = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
    @eks_config.role_arn          = output_value(stackputs, "RoleArn")
    @eks_config.security_group_id = output_value(stackputs, "SecurityGroup")
    @eks_config.subnet_ids        = %w(SubnetPublic1 SubnetPublic2 SubnetPrivate1 SubnetPrivate2).map do |key|
      output_value(vpc_stack, key)
    end
    private_subnets               = [output_value(vpc_stack, "SubnetPrivate1"), output_value(vpc_stack, "SubnetPrivate2")]
    @eks_config.cluster_name      = @cluster_name
    @eks_config.vpc_id            = vpc_id
    @eks_config.region            = @region
    @eks_config.private_subnets   = private_subnets

    write_bastion_params
    logger.info "Ensuring bastion stack #{bastion_stack_name}"
    Open3.capture2e(create_bastion_command) {|stdouterr, status| logger.debug stdouterr }

    logger.info "#{@cluster_name} IAM role is #{@eks_config.role_arn}"
    logger.info "VPC #{vpc_id} ready"
  end

  def dump_vpc_params(vpc_id)
    File.open(ACCESS_PARAMS, 'w') do |f|
      f.write(access_params(vpc_id).to_json)
    end
  end

  def bastion_params
    [
      {
        "ParameterKey"   => "KeyName",
        "ParameterValue" => @cluster_name
      },
      {
        "ParameterKey"   => "VpcId",
        "ParameterValue" => @vpc_id
      },
      {
        "ParameterKey"   => "SubnetId",
        "ParameterValue" => (@eks_config.subnet_ids - @eks_config.private_subnets).first
      }
    ]
  end

  def nat_params
    [
      {
        "ParameterKey"   => "VpcName",
        "ParameterValue" => vpc_name
      }
    ]
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

  def write_bastion_params
    File.open('bastion_params.json', 'w') { |f| f.puts bastion_params.to_json }
  end

  def write_nat_params
    File.open('nat_params.json', 'w') { |f| f.puts nat_params.to_json }
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
