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
            params:  {}
          },
          {
            channel: 'stable',
            name:    'nginx-ingress',
            version: '1.1.1',
            params:  ingress_params(config)
          }
        ]
      end

      private

      def ingress_params(config)
        cert       = config.acm_ingress_cert_arn
        tag        = 'service.beta.kubernetes.io'
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
    end
  end
end
