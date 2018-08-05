require 'yaml'
require 'fileutils'
require 'logger'
require 'open3'

class KubeConfigMerger
  attr_reader :logger

  AWS_USER = 'aws'

  def initialize(eks_config)
    @logger      = Logger.new(STDOUT)
    @eks_config  = eks_config
    @kube_dir    = File.expand_path(File.join(ENV.fetch("HOME"), ".kube"))
    @kube_config = File.join(@kube_dir, 'config')
  end

  def make_configs_happy
    if existing_config?
      merge_config
    else
      write_config_for_cluster
    end
  end

  private

  def cluster_name
    @eks_config.cluster_name
  end

  def certificate_authority
    @certificate_authority ||= `aws eks describe-cluster --name #{cluster_name} --query cluster.certificateAuthority.data`.chomp.gsub('"','')
  end

  def cluster_url
    @cluster_url ||= `aws eks describe-cluster --name #{cluster_name} --query cluster.endpoint`.chomp.gsub('"', '')
  end

  def cluster_config
    {
      'apiVersion'      => 'v1',
      'kind'            => 'Config',
      'clusters'        => [
        cluster
      ],
      'contexts'        => [
        context
      ],
      'current-context' => cluster_name,
      'users'           => [
        user
      ]
    }.to_yaml
  end

  def cluster
    {
      'cluster' => {
        'server'                     => cluster_url,
        'certificate-authority-data' => certificate_authority
      },
      'name'    => cluster_name
    }
  end

  def context
    {
      'context' => {
        'cluster' => cluster_name,
        'user'    => AWS_USER
      },
      'name'    => cluster_name
    }
  end

  def user
    {
      'name' => AWS_USER,
      'user' => {
        'exec' => {
          'command'    => 'heptio-authenticator-aws',
          'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
          'args'       => [
            'token',
            '-i',
            cluster_name,
            '-r',
            role
          ]
        }
      }
    }
  end

  def existing_config?
    true
  end

  def hash_with_value?(collection, key, value)
    collection.fetch(key, {}).find { |item| item['name'] == value }
  end

  def merge_config
    config          = YAML.load_file(@kube_config)
    merged_users    = hash_with_value?(config, "users", AWS_USER) ? {} : config.dig("users") << user
    merged_clusters = hash_with_value?(config, "clusters", cluster_name) ? {} : config.dig("clusters") << cluster
    merged_contexts = hash_with_value?(config, "contexts", cluster_name) ? {} : config.dig("contexts") << context
    new_config      = config.merge({ "users" => merged_users })
                        .merge({"clusters" => merged_clusters})
                        .merge({"contexts" => merged_contexts})
                        .merge({ 'current-context' => cluster_name })
                        .to_yaml

    File.open(@kube_config, 'w') { |f| f.write new_config }

    logger.info "Merged your existing kubectl config. Your cluster is now the current context"
    logger.info "'kubectl get node' should now work!"
  end

  def role
    @eks_config.role_arn
  end

  def write_config_for_cluster
    FileUtils.mkdir_p(@kube_dir)
    File.open(@kube_config, 'w') { |f| f.write cluster_config }
    logger.info "Created a new kubectl config file"
  end
end
