require 'test_helper'

class IngressComponentTest < ParallelTest
  def test_pod_running
    assert_pod_running 'nginx-ingress'
  end
end
