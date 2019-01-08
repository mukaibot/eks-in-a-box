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
    top_output, _status = Open3.capture2e('kubectl top node')
    top_output          = top_output.split("\n")

    if top_output.size > 1 && !top_output.include?('error')
      true
    elsif attempt < METRICS_MAX_ATTEMPT
      sleep METRICS_INTERVAL
      metrics_collected?(attempt + 1)
    else
      # Just write the error to the console
      puts top_output
      false
    end
  end
end
