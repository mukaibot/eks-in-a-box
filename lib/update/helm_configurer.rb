# frozen_string_literal: true

require 'open3'

module Update
  class HelmConfigurer
    MAX_ATTEMPTS = 100
    NAMESPACE    = 'eks-in-a-box'

    class << self
      def call(logger)
        configure_helm(logger) if helm_unconfigured?(logger)
      end

      private

      def helm_unconfigured?(logger)
        _version, status = Open3.capture2e("helm version --tiller-namespace #{NAMESPACE}")
        configured       = status.to_i.zero?
        configured ? logger.debug('Helm is configured') : logger.debug('Helm is not configured')
        !configured
      end

      def configure_helm(logger)
        logger.debug('Configuring Helm')
        status = Open3.popen2e("kubectl create namespace #{NAMESPACE}") do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            logger.debug line.chomp
          end

          wait_thread.value
        end
        abort("Error creating namespace #{NAMESPACE}") unless status.to_i.zero?

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
