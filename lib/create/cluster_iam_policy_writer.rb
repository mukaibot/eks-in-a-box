require 'json'

module Create
  class ClusterIAMPolicyWriter
    POLICY_FILE = File.expand_path(File.join(__dir__, '..', '..', 'templates', 'additional_cluster_iam_policies.json'))
    class << self
      def call(config, logger)
        logger.info "Adding additional policies from #{POLICY_FILE}"
        node_role = node_role_arn(config).split('/').last
        cmd = "aws iam put-role-policy --role-name #{node_role} --policy-name additional-iam-policies-eks-in-a-box --policy-document file://#{POLICY_FILE}"
        status = Open3.popen2e(cmd) do |_, stdout_stderr, wait_thread|
          while (line = stdout_stderr.gets)
            next if line.chomp.empty?
            logger.debug line.chomp
          end

          wait_thread.value
        end

        status.to_i.zero? ? status : exit(status.to_i)
      end

      private

      def stack_name(config)
        "eksctl-#{config.name}-nodegroup-0"
      end

      def outputs(config)
        describe_stack = `aws cloudformation describe-stacks --stack-name #{stack_name(config)}`.chomp

        JSON.parse(describe_stack)
          .dig('Stacks')
          .first
          .dig('Outputs')
      end

      def node_role_arn(config)
        outputs(config)
          .find { |o| o.fetch('OutputKey') == 'InstanceRoleARN' }
          .fetch('OutputValue')
      end
    end
  end
end
