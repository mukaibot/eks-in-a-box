require 'test_helper'
require 'eks_config'
require 'update/iam_role_mapper'

class IAMRoleMapperTest < ParallelTest
  def test_true_dat
    Update::IAMRoleMapper.stub :config_map_from_cluster, config_map_from_cluster do
      result = Update::IAMRoleMapper.call(config_additional_role)
      assert_equal(expected_with_additional, result)
    end
  end

  private

  def aws_role_arn
    'role-arn-mate'
  end

  def kube_role
    'edit-yo-deployment'
  end

  def config_additional_role
    config           = EksConfig.new
    config.map_roles = {
      user_name => {
        kube_roles:   [kube_role],
        aws_role_arn: aws_role_arn
      }
    }
    config
  end

  def expected_with_additional
    <<~YAML
      ---
      apiVersion: v1
      kind: ConfigMap
      data:
        mapRoles:
        - groups:
          - system:bootstrappers
          - system:nodes
          rolearn: arn:aws:iam::475385300542:role/eksctl-ekstatic-nodegroup-ng-2f-NodeInstanceRole-SG177NZZXR3X
          username: system:node:{{EC2PrivateDNSName}}
        - groups:
          - #{kube_role}
          rolearn: #{aws_role_arn}
          username: #{user_name}
    YAML
  end

  def config_map_from_cluster
    File.read(File.join(__dir__, 'fixtures', 'aws_auth_config_map_from_server.yml'))
  end

  def user_name
    'your-mate'
  end
end
