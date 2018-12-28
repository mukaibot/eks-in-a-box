require 'json'

module Create
  class NodeRoleFinder
    class << self
      def call(config)
        node_role_arn(config).split('/').last
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
