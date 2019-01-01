module CustomAssertions
  def assert_pod_running(name, namespace = 'eks-in-a-box', msg = nil)
    pod = `kubectl -n #{namespace} get pod | grep #{name}`.chomp
    status = pod.split(' ')[2]
    msg = ''
    if status.nil?
      msg = message(msg) { "Expected Pod '#{name}' to be running but it does not exist in namespace '#{namespace}'"}
    else
      msg = message(msg) { "Expected Pod '#{name}' to have status of 'Running' but was '#{status}'" }
    end
    assert(status == 'Running', msg)
  end
end
