require 'test_helper'
require 'uri'

class MetricsServerComponentTest < ParallelTest
  def test_pod_running
    assert_pod_running 'metrics-server'
  end

  def test_metrics_api_collection
    top_output = `kubectl top node`.chomp.split("\n")
    assert top_output.size > 1, 'Expected "kubectl top node" to have collected metrics, but it returned an error'
  end
end
