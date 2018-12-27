# frozen_string_literal: true

require 'yaml'
require 'tempfile'
require 'update/charts'

module Update
  class ComponentInstaller
    MAX_ATTEMPTS = 100
    NAMESPACE    = 'eks-in-a-box'

    class << self
      def call(config, logger)
        configure_helm(logger) if helm_unconfigured?(logger)
        apply_manifests(logger) if manifests.any?
        helminate(config, logger)
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
          while (line = stdout_stderr.gets)
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status
      end

      def apply_command(manifest)
        "kubectl apply -f #{manifest}"
      end

      def chart_values(chart, logger)
        values = chart.fetch(:params)
        return nil if values.empty?

        @tmpfile = Tempfile.new('helm')
        @tmpfile.write(values.to_yaml)
        @tmpfile.flush
        "--values #{@tmpfile.path}"
      end

      def helm_command(chart, logger)

        [
          "helm upgrade #{chart.fetch(:name)}",
          "#{chart.fetch(:channel)}/#{chart.fetch(:name)}",
          '--install',
          "--namespace #{NAMESPACE}",
          "--tiller-namespace #{NAMESPACE}",
          "--version #{chart.fetch(:version)}",
          chart_values(chart, logger)
        ].compact.join(' ')
      end

      def helminate(config, logger)
        charts = Charts.all(config)
        logger.info("Using Helm to install #{charts.size} charts")

        charts.each do |chart|
          logger.info("Executing '#{helm_command(chart, logger)}'")
          begin
            status = Open3.popen2e(helm_command(chart, logger)) do |_, stdout_stderr, wait_thread|
              while (line = stdout_stderr.gets)
                logger.debug line.chomp
              end

              wait_thread.value
            end

            status
          ensure
            @tmpfile&.close
          end
        end
      end

      def manifests
        Dir.glob('features/**/*.yaml') + Dir.glob('features/**/*.yml')
      end

      def helm_unconfigured?(logger)
        _version, status = Open3.capture2e('helm version')
        configured       = status.to_i.zero?
        configured ? logger.debug('Helm is configured') : logger.debug('Helm is not configured')
        !configured
      end

      def configure_helm(logger)
        logger.debug('Configuring Helm')
        status = Open3.popen2e("kubectl create serviceaccount --namespace #{NAMESPACE} tiller") do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            logger.debug line.chomp
          end

          wait_thread.value
        end
        abort('Error creating Helm service account') unless status.to_i.zero?
        status = Open3.popen2e("kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=#{NAMESPACE}:tiller") do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            logger.debug line.chomp
          end

          wait_thread.value
        end

        abort('Error configuring Helm service account') unless status.to_i.zero?

        Open3.popen2e("helm init --service-account tiller --tiller-namespace #{NAMESPACE}") do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            logger.debug line.chomp
          end

          wait_thread.value
        end

        abort('Timed out waiting for Helm to install') unless wait_for_helm(logger)
      end

      def wait_for_helm(logger, attempt = 0)
        return false if attempt == MAX_ATTEMPTS

        if helm_unconfigured?(logger)
          attempt += 1
          sleep(3)
          wait_for_helm(logger, attempt)
        else
          true
        end
      end
    end
  end
end
