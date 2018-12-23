require 'update/charts'

module Update
  class ComponentInstaller
    class << self
      def call(logger)
        configure_helm(logger) if helm_unconfigured?(logger)
        apply_manifests(logger) if manifests.any?
        helminate(logger)
      end

      private

      def apply_manifests(logger)
        logger.info("Applying #{manifests.join(', ')}")
        manifests.each { |manifest| apply(manifest, logger) }
        logger.info("Applied #{manifests.size} manifests")
      end

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

      def helm_command(chart)
        values = chart.fetch(:params).map {|k,v| "#{k}=#{v}"}.join("--values ")
        [
          "helm install",
          "#{chart.fetch(:channel)}/#{chart.fetch(:name)}",
          "--version #{chart.fetch(:version)}",
          values
        ].join(' ')
      end

      def helminate(logger)
        logger.info("Using Helm to install #{Charts::DEFAULTS.size} charts")

        Charts::DEFAULTS.each do |chart|
          logger.debug("Executing '#{helm_command(chart)}'")
          status = Open3.popen2e(helm_command(chart)) do |_, stdout_stderr, wait_thread|
            while (line = stdout_stderr.gets) do
              logger.debug line.chomp
            end

            wait_thread.value
          end

          status
        end
      end

      def manifests
        Dir.glob('features/**/*.yaml') + Dir.glob('features/**/*.yml')
      end

      def helm_unconfigured?(logger)
        _version, status = Open3.capture2e('helm version')
        configured       = status.to_i.zero?
        configured ? logger.debug("Helm is configured") : logger.debug("Helm is not configured")
        configured
      end

      def configure_helm(logger)
        logger.debug("Configuring Helm")
        status = Open3.popen2e('helm init') do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets) do
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status
      end
    end
  end
end
