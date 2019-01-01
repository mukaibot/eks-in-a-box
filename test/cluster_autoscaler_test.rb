require 'test_helper'

class ClusterAutoscalerComponentTest < ParallelTest
  def test_pod_running
    assert_pod_running 'cluster-autoscaler-aws'
  end
end
