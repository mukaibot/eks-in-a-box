require 'logger'
require 'open3'
require 'yaml'

class EksCreator
  attr_reader :logger

  def initialize(config)
    @config_path = config
    @logger      = Logger.new(STDOUT)
  end

  def call
    initiate_creation
    wait_for_cluster
    self
  end

  private

  def config
    @config ||= YAML.load_file(@config_path)
  end

  def create_command
    [
      "aws",
      "eks",
      "create-cluster",
      "--name",
      cluster_name,
      "--role-arn",
      role_arn,
      "--resources-vpc-config",
      resources,
      "--region",
      region
    ].join(" ")
  end

  def cluster_name
    config.fetch("cluster_name")
  end

  def initiate_creation
    logger.info "Creating cluster #{cluster_name}"
    Open3.capture2e(create_command) do |stderrout, _|
      logger.info stderrout
    end
  end

  def region
    config.fetch("region")
  end

  def resources
    "subnetIds=#{subnets.join(",")},securityGroupIds=#{security_group}"
  end

  def role_arn
    config.fetch("role_arn")
  end

  def subnets
    config.fetch("subnets")
  end

  def security_group
    config.fetch("access_group")
  end

  def wait_command
    [
      "aws",
      "eks",
      "describe-cluster",
      "--name",
      cluster_name,
      "--region",
      region
    ].join(" ")
  end

  def wait_for_cluster
    while poll do
      logger.debug "Waiting a few seconds for cluster"
      sleep 3
    end
  end

  def poll
    output, _ = Open3.capture2e(wait_command)
    JSON.parse(output).fetch("cluster").fetch("status") == "CREATING"
  end
end
