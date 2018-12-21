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
      status = Open3.popen2e(create_command) do |_, stdout_stderr, wait_thread|
        while (line = stdout_stderr.gets) do
          puts line
        end

        wait_thread.value
      end

      status
    end
  end
end
