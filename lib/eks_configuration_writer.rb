require 'logger'
require 'yaml'

class EksConfigurationWriter
  attr_reader :logger, :vpc_id, :cluster_name, :role_arn

  def initialize(vpc_id, cluster_name, role_arn)
    @logger       = Logger.new(STDOUT)
    @vpc_id       = vpc_id
    @cluster_name = cluster_name
    @role_arn     = role_arn
    @config_hash  = config_hash(vpc_id, cluster_name, role_arn)
  end

  def call
    File.open(config_file_name, 'w') do |f|
      f.write(@config_hash.to_yaml)
    end

    logger.info "Wrote config to #{config_file_name}"
  end

  private

  def config_file_name
    "#{cluster_name}.config.yml"
  end

  def config_hash(vpc_id, cluster_name, role_arn)
    {
      "vpc_id"       => vpc_id,
      "role_arn"     => role_arn,
      "cluster_name" => cluster_name
    }
  end
end
