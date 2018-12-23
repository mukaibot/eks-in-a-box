module Prereqs
  class ClientBinaryInstaller
    attr_reader :logger, :platform

    def initialize(platform)
      @logger       = Logger.new(STDOUT)
      @platform     = platform
      @bin_path     = "#{ENV['HOME']}/.local/bin"
      @bins_in_path = ENV['PATH'].split(":").include?(@bin_path)
      @kubeconfig   = "#{ENV['HOME']}/.kube/config"

      @installed_binary = false
    end

    def call
      logger.debug "Checking for #{client_binaries.map { |bin| bin.fetch(:name) }.join(", ")}"

      install_client_binaries

      logger.info "I added some binaries to your machine." if @installed_binary
      logger.info "Please ensure #{@bin_path} is added to your $PATH" unless @bins_in_path
      self
    end

    private

    def install_client_binaries
      client_binaries.each do |bin|
        found = `which #{bin[:name]}`.chomp
        if found != ""
          logger.info "Found #{bin[:name]} at #{found}"
        else
          install(bin)
        end
      end
    end

    def client_binaries
      [
        {
          name: 'kubectl',
          url:  "https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/#{platform}/amd64/kubectl"
        },
        {
          name: 'aws-iam-authenticator',
          url:  "https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/#{platform}/amd64/aws-iam-authenticator",
        },
        {
          name: 'eksctl',
          url:  "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_#{platform}_amd64.tar.gz"
        },
        {
          name: 'helm',
          url:  "https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-#{platform}-amd64.tar.gz"
        }
      ]
    end

    def install(bin)
      name = bin.fetch(:name)
      url  = bin.fetch(:url)
      dest = File.join(@bin_path, name)
      FileUtils.mkdir_p(@bin_path)
      @installed_binary = true
      logger.info "Installing #{name} to #{@bin_path}"

      if name == 'helm'
        helm(bin, @bin_path)
      elsif url.end_with?('gz')
        tarred_bin(bin, dest)
      else
        go_bin(bin, dest)
      end
    end

    private

    def helm(bin, dest)
      dl_tmp = "/tmp/#{platform}-amd64"
      `curl --silent --location "#{bin.fetch(:url)}" | tar xz -C /tmp && mv #{dl_tmp}/helm #{dest} && mv #{dl_tmp}/tiller #{dest}`
    end

    def tarred_bin(bin, dest)
      `curl --silent --location "#{bin.fetch(:url)}" | tar xz -C /tmp && mv /tmp/#{bin.fetch(:name)} #{dest}`
    end

    def go_bin(bin, dest)
      File.open(dest, "w") { |f| IO.copy_stream(open(bin.fetch(:url)), f) }
      FileUtils.chmod(755, dest)
    end
  end
end
