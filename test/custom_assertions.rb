module CustomAssertions
  POD_RUNNING_MAX_ATTEMPTS = 100
  POD_RUNNING_INTERVAL     = 3

  def assert_pod_running(name, namespace = 'eks-in-a-box', attempt = 0, msg = nil)
    pod    = `kubectl -n #{namespace} get pod | grep #{name}`.chomp
    status = pod.split(' ')[2]

    if status.nil?
      msg = message(msg) { "Expected Pod '#{name}' to be running but it does not exist in namespace '#{namespace}'" }
    else
      msg = message(msg) { "Expected Pod '#{name}' to have status of 'Running' but was '#{status}'" }
    end

    if status == 'Running'
      assert true
    elsif attempt < POD_RUNNING_MAX_ATTEMPTS
      sleep POD_RUNNING_INTERVAL
      assert_pod_running(name, namespace, attempt + 1, msg)
    else
      pod_name = pod.split("\n")[1].split(' ').first
      puts "Logs from failed pod #{pod_name}:"
      puts `kubectl -n #{namespace} logs #{pod_name}`.chomp
      flunk msg
    end
  end
end
