require 'logger'
require 'yaml'

class EksConfigurationWriter
  attr_reader :logger, :cluster_name

  def initialize(eks_config)
    @logger       = Logger.new(STDOUT)
    @config       = eks_config
    @config_hash  = config_hash(eks_config)
    @cluster_name = eks_config.cluster_name
  end

  def call
    File.open(config_file_name, 'w') do |f|
      f.write(@config_hash.to_yaml)
    end

    logger.info "Wrote config to #{config_file_name}"
    self
  end

  def config_file_name
    "#{cluster_name}.config.yml"
  end

  private

  def config_hash(config)
    {
      "cluster_name" => config.cluster_name,
      "access_group" => config.security_group_id,
      "region"       => config.region,
      "role_arn"     => config.role_arn,
      "subnets"      => config.subnet_ids,
      "vpc_id"       => config.vpc_id,
    }
  end
end
