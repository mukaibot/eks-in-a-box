module Update
  # Figures out what is the required mapping for EKS to work, then
  # replaces all other mappings with whatever is specified in config
  class IAMRoleMapper
    CONFIG_MAP_KEYS = %w(apiVersion data kind).freeze
    NODE_MAPPING    = 'system:node:{{EC2PrivateDNSName}}'

    class << self
      def call(config)
        manifests(config_map_from_cluster, config)
      end

      private

      def config_map_from_cluster
        config_map_command = 'kubectl -n kube-system get configmap aws-auth -o yaml'.chomp
        output, status     = Open3.capture2e(config_map_command)
        status.to_i.zero? ? YAML.load(output).slice(*CONFIG_MAP_KEYS) : abort("Could not get config map from cluster: #{output}")
      end

      # The roles returned from this are required for node groups to work with EKS
      def eks_map(server_config_map)
        YAML.load(server_config_map.dig('data', 'mapRoles'))
          .select { |r| r.fetch('rolearn').include?('NodeInstanceRole') }
      end

      def mappings_from_config(config)
        config.map_roles.keys.map do |mapping_key|
          mapping    = config.map_roles[mapping_key]
          username   = mapping_key
          kube_roles = mapping.fetch('kube_roles')
          aws_role   = mapping.fetch('aws_role_arn')

          {
            'groups'   => kube_roles,
            'rolearn'  => aws_role,
            'username' => username
          }
        end
      end

      def role_binding(user_name, cluster_role)
        {
          'kind'       => 'ClusterRoleBinding',
          'apiVersion' => 'rbac.authorization.k8s.io/v1',
          'metadata'   => {
            'name' => user_name
          },
          'subjects'   => [
            {
              'kind'      => 'User',
              'name'      => user_name,
              'namespace' => 'eks-in-a-box'
            }
          ],
          'roleRef'    => {
            'kind'     => 'ClusterRole',
            'name'     => cluster_role,
            'apiGroup' => 'rbac.authorization.k8s.io'
          }
        }
      end

      def role_bindings(cluster_config)
        cluster_config.map_roles.keys.map do |role_name|
          cluster_config.map_roles.fetch(role_name).fetch('kube_roles').map do |role|
            role_binding(role_name, role)
          end
        end.flatten
      end

      def manifests(aws_config_map, cluster_config)
        mappings   = eks_map(aws_config_map) + mappings_from_config(cluster_config)
        config_map = {
          'apiVersion' => 'v1',
          'kind'       => 'ConfigMap',
          'data'       => {
            'mapRoles' => mappings.to_yaml
          },
          'metadata'   => {
            'name'      => 'aws-auth',
            'namespace' => 'kube-system'
          }
        }
        YAML.dump_stream(config_map, *role_bindings(cluster_config))
      end
    end
  end
end
