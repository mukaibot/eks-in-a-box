module Commands
  class WriteConfig
    class << self
      def call(config, logger)
        if config.valid?
          `eksctl utils write-kubeconfig --name #{config.name}`.chomp

          puts "Wrote client configuration for cluster '#{config.name}' to ~/.kube/config"
        else
          logger.fatal "Missing values for #{config.missing_attributes.join(', ')}"
          exit 1
        end
      end
    end
  end
end
