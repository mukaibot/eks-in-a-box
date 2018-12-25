require 'update/component_installer'

module Commands
  class Update
    class << self
      def call(config, logger)
        validate!(config)
        ::Update::ComponentInstaller.call(config, logger)
      end

      private

      def validate!(config)
        current_context        = `kubectl config current-context`.chomp
        cluster_matches_config = current_context.include?(config.name)

        abort("Your current context is '#{current_context}' but your configuration defines the cluster as '#{config.name}'. Please switch your kubectl context to use the cluster '#{config.name}' with 'kubectl config use-context' before running this command") unless cluster_matches_config
      end
    end
  end
end
