desc 'Teardown the test cluster'
task :teardown do
  puts "Tearing down cluster"
  teardown_command = 'bin/eks-box -o delete -c config.yml'
  Open3.popen2e(teardown_command) do |_, stdout_stderr, wait_thread|
    while (line = stdout_stderr.gets) do
      puts line
    end

    wait_thread.value
  end
end
