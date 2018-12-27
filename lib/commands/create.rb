require 'create/eks_creator'
require 'create/cluster_iam_policy_writer'
require 'prereqs/checker'

module Commands
  class Create
    class << self
      def call(config, logger)
        Prereqs.call

        if config.valid?
          ::Create::EksCreator.new(config, logger).call
          ::Create::ClusterIAMPolicyWriter.call(load_config(options, logger), logger)
          Commands::Update.call(config, logger)
        else
          logger.fatal "Missing values for #{config.missing_attributes.join(', ')}"
          exit 1
        end
      end
    end
  end
end
