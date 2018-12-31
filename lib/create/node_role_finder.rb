require 'json'

module Create
  class NodeRoleFinder
    class << self
      def call(config)
        node_role_arn(config).split('/').last
      end

      private

      def stack_name(config)
        "eksctl-#{config.name}-nodegroup"
      end

      def outputs(config)
        describe_stack = `aws cloudformation describe-stacks --query 'Stacks[?starts_with(StackName,\`#{stack_name(config)}\`)]'`.chomp

        JSON.parse(describe_stack)
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
