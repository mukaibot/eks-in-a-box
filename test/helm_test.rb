require 'test_helper'

class HelmComponentTest < ParallelTest
  def test_pod_running
    assert_pod_running 'tiller-deploy'
  end
end
