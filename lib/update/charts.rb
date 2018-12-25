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
            params:  []
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
        annotation = 'controller.service.annotations.service.beta.kubernetes.io'
        return {} if cert.nil?

        params = {
          'aws-load-balancer-ssl-cert':                cert,
          'aws-load-balancer-backend-protocol':        "http",
          'aws-load-balancer-ssl-ports':               "https",
          'aws-load-balancer-connection-idle-timeout': '3600'
        }

        params.map { |k, v| "#{annotation}.#{k}=#{v}" }
      end
    end
  end
end
