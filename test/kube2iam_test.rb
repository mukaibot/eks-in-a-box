require 'test_helper'

class Kube2IAMComponentTest < ParallelTest
  def test_pod_running
    assert_pod_running 'kube2iam'
  end
end
