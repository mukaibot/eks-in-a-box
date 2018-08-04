require 'json'
require 'logger'
require 'open3'

class VpcCreator
  attr_reader :logger, :cluster_name

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

  def vpc_name
    @cluster_name + "-vpc"
  end

  private

  def create_vpc
    create_command = [
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

    wait_command = [
      "aws",
      "cloudformation",
      "wait",
      "stack-create-complete",
      "--stack-name",
      vpc_name,
      "--region",
      @region
    ].join(" ")

    stdout, stderr, status = Open3.capture3(create_command)

    need_to_wait = stdout.include?("arn:aws:cloudformation")

    if need_to_wait
      stdout, stderr, status = Open3.capture3(wait_command)
    end

    logger.info "VPC '#{vpc_name}' ready"
  end

  # Todo - extract this to bin/eks-box or similar
  def get_cluster_name
    logger.info "What should we call your cluster? Short DNS name is recommended, a-z, dashes and dots are allowed. EG: my-cluster"
    @cluster_name = gets.chomp

    "Need a valid cluster name" if @cluster_name.nil? || @cluster_name.empty?
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
