# frozen_string_literal: true

module Update
  class Charts
    class << self
      def all(config)
        [
          {
            channel: 'stable',
            name:    'metrics-server',
            version: '2.0.4',
            params:  metrics_server_params
          },
          {
            channel: 'stable',
            name:    'nginx-ingress',
            version: '1.1.1',
            params:  ingress_params(config)
          },
          {
            channel: 'stable',
            name:    'cluster-autoscaler',
            version: '0.11.0',
            params:  cluster_autoscaler_params(config)
          },
        ]
      end

      private

      def cluster_autoscaler_params(config)
        {
          'autoDiscovery' => {
            'clusterName' => config.name
          },
          'awsRegion'     => config.region,
          'sslCertPath'   => '/etc/kubernetes/pki/ca.crt',
          'rbac'          => {
            'create' => true
          }
        }
      end

      def ingress_params(config)
        cert = config.acm_ingress_cert_arn
        tag  = 'service.beta.kubernetes.io'
        return {} if cert.nil?

        params = {
          "#{tag}/aws-load-balancer-ssl-cert"                => cert,
          "#{tag}/aws-load-balancer-backend-protocol"        => "http",
          "#{tag}/aws-load-balancer-ssl-ports"               => "https",
          "#{tag}/aws-load-balancer-connection-idle-timeout" => '3600'
        }

        {
          'controller' => {
            'service' => {
              'annotations' => params
            }
          }
        }
      end

      # Fix for the Metrics server resolution issue when using customzied domain-name in the VPC DHCP options set
      # See https://github.com/pahud/amazon-eks-workshop/blob/0d02f0ca64ad3675a5df5a8398b355128d864980/04-scaling/hpa/README.md#metrics-server-resolution-issue-when-using-customzied-domain-name-in-your-vpc-dhcp-options-set
      def metrics_server_params
        {
          'args' => [
            '--logtostderr',
            '--kubelet-insecure-tls',
            '--kubelet-preferred-address-types=InternalIP'
          ]
        }
      end
    end
  end
end
