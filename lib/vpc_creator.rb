require 'json'
require 'logger'
require 'open3'

class VpcCreator
  attr_reader :logger, :cluster_name, :role_arn

  ACCESS_PARAMS = 'access_params.json'

  def initialize
    @region             = 'us-west-2'
    @logger             = Logger.new(STDOUT)
    @availability_zone1 = @region + 'a'
    @availability_zone2 = @region + 'b'
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
      @region
    ].join(" ")
  end

  # Todo - refactor me!
  def create_vpc
    Open3.capture3(create_command(vpc_name))
    Open3.capture3(wait_command(vpc_name))

    describe_stack        = "aws cloudformation describe-stacks --stack-name #{vpc_name}"
    stack, stderr, status = Open3.capture3(describe_stack)

    vpc_id = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
               .find { |out| out.fetch("OutputKey") == "Vpc" }
               .fetch("OutputValue")

    dump_vpc_params(vpc_id)
    access_stack, stderr, status = Open3.capture3(create_access_command(access_stack_name))
    Open3.capture3(wait_command(access_stack_name))
    describe_access_stack  = "aws cloudformation describe-stacks --stack-name #{access_stack_name}"
    stack, stderr, status  = Open3.capture3(describe_access_stack)
    @role_arn              = JSON.parse(stack).fetch("Stacks").first.fetch("Outputs")
                               .find { |out| out.fetch("OutputKey") == "RoleArn" }
                               .fetch("OutputValue")

    logger.debug "#{@cluster_name} IAM role is #{@role_arn}"
    logger.info "VPC '#{vpc_name}' ready"
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
