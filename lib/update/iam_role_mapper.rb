module Update
  # Figures out what is the required mapping for EKS to work, then
  # replaces all other mappings with whatever is specified in config
  class IAMRoleMapper
    CONFIG_MAP_KEYS = %w(apiVersion data kind).freeze
    NODE_MAPPING    = 'system:node:{{EC2PrivateDNSName}}'

    class << self
      def call(config)
        update(config_map_from_cluster, config)
      end

      private

      def config_map_from_cluster
        config_map_command = 'kubectl -n kube-system get configmap aws-auth -o yaml'.chomp
        status, output     = Open3.capture2e(config_map_command)
        status.to_i.zero? ? YAML.load(output).slice(*CONFIG_MAP_KEYS) : abort("Could not get config map from cluster: #{output}")
      end

      # The roles returned from this are required for node groups to work with EKS
      def eks_map(server_config_map)
        base_yaml  = YAML.load(server_config_map)
        roles_hash = YAML.load(base_yaml.dig('data', 'mapRoles'))

        roles_hash.select { |r| r.fetch('rolearn').include?('NodeInstanceRole') }
      end

      def mappings_from_config(config)
        config.map_roles.keys.map do |mapping_key|
          mapping    = config.map_roles[mapping_key]
          username   = mapping_key
          kube_roles = mapping.fetch(:kube_roles)
          aws_role   = mapping.fetch(:aws_role_arn)

          {
            'groups'   => kube_roles,
            'rolearn'  => aws_role,
            'username' => username
          }
        end
      end

      def update(aws_config_map, cluster_config)
        {
          'apiVersion' => 'v1',
          'kind'       => 'ConfigMap',
          'data'       => {
            'mapRoles' => eks_map(aws_config_map) + mappings_from_config(cluster_config)
          }
        }.to_yaml
      end
    end
  end
end
