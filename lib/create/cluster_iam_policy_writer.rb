require_relative 'node_role_finder'

module Create
  class ClusterIAMPolicyWriter
    POLICY_FILE = File.expand_path(File.join(__dir__, '..', '..', 'templates', 'additional_cluster_iam_policies.json'))
    POLICY_NAME = 'additional-iam-policies-eks-in-a-box'

    class << self
      def call(config, logger)
        logger.info "Adding additional IAM policies from #{POLICY_FILE}"
        node_role = Create::NodeRoleFinder.call(config)
        cmd       = "aws iam put-role-policy --role-name #{node_role} --policy-name #{POLICY_NAME} --policy-document file://#{POLICY_FILE}"
        status    = Open3.popen2e(cmd) do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            next if line.chomp.empty?
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status.to_i.zero? ? status : exit(status.to_i)
      end
    end
  end
end
