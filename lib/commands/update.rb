module Commands
  class Update
    class << self
      def call(config, logger)
        validate!(config)
        logger.info("Applying #{manifests.join(', ')}")
        manifests.each { |manifest| apply(manifest, logger) }
        logger.info("Applied #{manifests.size} manifests")
      end

      private

      def apply(manifest, logger)
        logger.info("Applying #{manifest}")
        status = Open3.popen2e(apply_command(manifest)) do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets) do
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status
      end

      def apply_command(manifest)
        "kubectl apply -f #{manifest}"
      end

      def manifests
        Dir.glob('features/**/*.yaml') + Dir.glob('features/**/*.yml')
      end

      def validate!(config)
        current_context = `kubectl config current-context`.chomp
        cluster_matches_config = current_context.include?(config.name)

        abort("Your current context is '#{current_context}' but your configuration defines the cluster as '#{config.name}'. Please switch your kubectl context to use the cluster '#{config.name}' with 'kubectl config use-context' before running this command") unless cluster_matches_config
      end
    end
  end
end
