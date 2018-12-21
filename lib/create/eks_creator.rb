require 'logger'
require 'open3'
require 'yaml'

module Create
  class EksCreator
    attr_reader :config, :logger

    def initialize(config, logger)
      @config = config
      @logger = logger
    end

    def call
      initiate_creation
      # wait_for_cluster
      # if cluster_status == "ACTIVE"
      #   logger.info "Success! Run '#{wait_command}' to get details"
      # else
      #   logger.error "Aww shit. Something bad happened and your cluster did not become active. Run '#{wait_command}' to debug."
      # end

      self
    end

    private

    def create_command
      [
        "eksctl",
        "create",
        "cluster",
        "--region=#{config.region}",
        "--node-private-networking",
        "--name=#{config.name}",
        "--ssh-access",
        "--ssh-public-key=#{config.keypair}",
        "--vpc-private-subnets=#{config.private_subnets.join(',')}",
        "--vpc-public-subnets=#{config.public_subnets.join(',')}",
      ].join(" ")
    end

    def initiate_creation
      logger.info "Creating cluster '#{config.name}'"
      logger.debug create_command
      # Open3.capture2e(create_command) do |stderrout, _|
      #   logger.info stderrout
      # end
    end

    # def wait_command
    #   [
    #     "aws",
    #     "eks",
    #     "describe-cluster",
    #     "--name",
    #     cluster_name,
    #     "--region",
    #     region
    #   ].join(" ")
    # end

    # def wait_for_cluster
    #   logger.debug wait_command
    #   while poll do
    #     logger.debug "Waiting for cluster"
    #     sleep 30
    #   end
    # end
    #
    # def poll
    #   cluster_status == "CREATING"
    # end
    #
    # def cluster_status
    #   output, _ = Open3.capture2e(wait_command)
    #   JSON.parse(output).fetch("cluster").fetch("status")
    # end
  end
end
