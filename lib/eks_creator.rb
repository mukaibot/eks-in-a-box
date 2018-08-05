require 'open3'
require 'yaml'

class EksCreator
  "aws eks create-cluster --name devel --role-arn arn:aws:iam::111122223333:role/eks-service-role-AWSServiceRoleForAmazonEKS-EXAMPLEBKZRQR --resources-vpc-config subnetIds=subnet-a9189fe2,subnet-50432629,securityGroupIds=sg-f5c54184"

  def initialize(config)
    @config_path = config
  end

  def call

  end

  private

  def config
    @config ||= YAML.load(@config_path)
  end
end
