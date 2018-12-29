require 'yaml'
require 'open3'
require 'json'

desc 'Create a cluster for running component and E2E tests'
task :setup do
  cluster_name = configure_cluster
  check_cluster_does_not_exist(cluster_name)
  create_test_cluster(cluster_name)
end

private

def configure_cluster
  config = File.expand_path(File.join(__dir__, '..', '..', '..', 'config.yml'))
  `bin/eks-box -o generate`
  cluster_name = YAML.load_file(config).dig('name')
  abort('Something unexpected happened with the bloody config') if cluster_name.nil?
  cluster_name
end

def check_cluster_does_not_exist(cluster_name)
  _, status = Open3.capture2e("aws eks describe-cluster --name #{cluster_name}")
  abort("Test cluster #{cluster_name} seems to already exist?!") if status.exitstatus.to_i.zero?
end

def create_test_cluster(cluster_name)
  create_command = 'bin/eks-box -o create -c config.yml'
  Open3.popen2e(create_command) do |_, stdout_stderr, wait_thread|
    while (line = stdout_stderr.gets) do
      puts line
    end

    wait_thread.value
  end

  output = JSON.parse(`aws eks describe-cluster --name #{cluster_name}`.chomp)
  abort("Cluster #{cluster_name} has unexpected status") unless output.dig('cluster', 'status') == 'ACTIVE'
end
