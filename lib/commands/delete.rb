require 'create/cluster_iam_policy_writer'

module Commands
  class Delete
    class << self
      def call(config, logger)
        logger.info("Deleting cluster #{config.name}")
        remove_policy(config, logger)
        delete_cluster(config, logger)
      end

      private

      def delete_cluster(config, logger)
        cmd    = "eksctl delete cluster #{config.name}"
        status = Open3.popen2e(cmd) do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            next if line.chomp.empty?
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status.to_i.zero? ? status : exit(status.to_i)
      end

      def remove_policy(config, logger)
        node_role       = ::Create::NodeRoleFinder.call(config)
        already_deleted = false
        cmd             = "aws iam delete-role-policy --role-name #{node_role} --policy-name #{::Create::ClusterIAMPolicyWriter::POLICY_NAME}"
        logger.debug("Removing additional IAM policies with command '#{cmd}'")
        status = Open3.popen2e(cmd) do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            next if line.chomp.empty?

            already_deleted = true if line.include?('NoSuchEntity')
            logger.debug line.chomp
          end

          wait_thread.value
        end

        return if already_deleted

        status.to_i.zero? ? status : exit(status.to_i)
      end
    end
  end
end
