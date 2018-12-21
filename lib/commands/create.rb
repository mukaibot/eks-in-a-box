require 'net/http'
require 'json'
require 'fileutils'
require 'open-uri'
require 'yaml'

require 'client_binary_installer'
require 'eks_configuration_writer'
require 'eks_creator'
require 'eks_node_creator'
require 'kube_config_merger'
require 'prerequisite_checker'
require 'ssh_key_creator'
require 'vpc_creator'

module Commands
  class Create
    class << self
      def call
        PrerequisiteChecker.new.check!
        ClientBinaryInstaller.new(PLATFORM).call

        puts "What should we call your cluster? Short DNS name is recommended, a-z, dashes and dots are allowed. EG: my-cluster"
        cluster_name = gets.chomp
        abort("Need a valid cluster name") if cluster_name.nil? || cluster_name.empty?
        ssh_key_creator = SSHKeyCreator.new(cluster_name).upsert

        vpc_creator = VpcCreator.new(cluster_name)
        vpc_creator.call
        config          = vpc_creator.eks_config
        eks_config      = EksConfigurationWriter.new(config).call
        config.key_name = ssh_key_creator.key_name

        EksCreator.new(eks_config.config_file_name).call
# Merging the config is required so that the config map can be applied.
# Without this the nodes cannot join the cluster
        KubeConfigMerger.new(config).make_configs_happy
        EksNodeCreator.new(config).call
      end
    end
  end
end