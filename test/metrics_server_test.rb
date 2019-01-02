require 'test_helper'
require 'uri'

class MetricsServerComponentTest < ParallelTest
  METRICS_MAX_ATTEMPT = 100
  METRICS_INTERVAL    = 3

  def test_pod_running
    assert_pod_running 'metrics-server'
  end

  def test_metrics_api_collection
    assert metrics_collected?, 'Expected "kubectl top node" to have collected metrics, but it returned an error'
  end

  private

  def metrics_collected?(attempt = 0)
    top_output = `kubectl top node`.chomp.split("\n")
    if top_output.size > 1
      true
    elsif attempt < METRICS_MAX_ATTEMPT
      sleep METRICS_INTERVAL
      metrics_collected?(attempt + 1)
    else
      false
    end
  end
end
