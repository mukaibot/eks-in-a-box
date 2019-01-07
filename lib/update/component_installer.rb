# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'tempfile'
require 'update/charts'
require 'update/helm_installer'
require 'update/iam_role_mapper'

module Update
  class ComponentInstaller
    NAMESPACE = 'eks-in-a-box'

    class << self
      def call(config, logger)
        HelmConfigurer.call(logger)
        apply_role_mappings(config, logger) if config.map_roles.any?
        apply_manifests(logger) if manifests.any?
        helminate(config, logger)
      end

      private

      def apply_manifests(logger)
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

      def chart_values(chart)
        values = chart.fetch(:params)
        return nil if values.empty?

        @tmpfile = Tempfile.new('helm')
        @tmpfile.write(values.to_yaml)
        @tmpfile.flush
        "--values #{@tmpfile.path}"
      end

      def apply_role_mappings(config, logger)
        role_count = config.map_roles.keys.size
        number     = role_count == 1 ? 'role' : 'roles'
        logger.debug("Writing manifest for #{role_count} additional #{number}")

        Tempfile.open('iam_role') do |file|
          file.write(Update::IAMRoleMapper.call(config))
          file.flush
          apply(file.path, logger)
        end
      end

      def helm_command(chart)
        [
          "helm upgrade #{chart.fetch(:name)}",
          "#{chart.fetch(:channel)}/#{chart.fetch(:name)}",
          '--install',
          "--namespace #{chart.fetch(:namespace, NAMESPACE)}",
          "--tiller-namespace #{NAMESPACE}",
          "--version #{chart.fetch(:version)}",
          chart_values(chart)
        ].compact.join(' ')
      end

      def helminate(config, logger)
        charts = Charts.all(config)
        logger.info("Using Helm to install #{charts.size} charts")

        charts.each do |chart|
          logger.info("Executing '#{helm_command(chart)}'")
          begin
            status = Open3.popen2e(helm_command(chart)) do |_, stdout_stderr, wait_thread|
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
    end
  end
end
