require 'logger'
require 'open3'

class SSHKeyCreator
  attr_reader :logger

  def initialize(cluster_name)
    @cluster_name = cluster_name
    @logger       = Logger.new(STDOUT)
  end

  def upsert
    if File.exists?(ssh_key_name)
      logger.debug "Found existing SSH key for cluster '#{ssh_key_name}'"
    else
      logger.debug "Generating a new SSH key for cluster '#{ssh_key_name}'"
      generate
    end

    import
    self
  end

  def key_name
    @cluster_name
  end

  private

  def generate
    gen_command = [
      "ssh-keygen",
      "-t",
      "rsa",
      "-N",
      "''", # blank password
      "-f",
      ssh_key_name,
      "-C",
      "'Keypair for EKS #{@cluster_name}'",
      "-q"
    ].join(" ")

    Open3.capture2e(gen_command) { |std, status| logger.debug std}
  end

  def public_key
    File.read(ssh_pub_key_name)
  end

  def import
    import_command = [
      "aws",
      "ec2",
      "import-key-pair",
      "--key-name",
      @cluster_name,
      "--public-key-material",
      "'#{public_key}'"
    ].join(" ")

    Open3.capture2e(import_command)
  end

  def ssh_key_name
    "#{@cluster_name}.key"
  end

  def ssh_pub_key_name
    "#{@cluster_name}.key.pub"
  end
end
