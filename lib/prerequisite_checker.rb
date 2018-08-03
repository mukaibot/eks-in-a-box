require 'logger'

class PrerequisiteChecker
  attr_reader :logger

  DEPS_DIR = "deps"
  DEPS     = [
    {
      name: "rea-vpc",
      url:  "git@git.realestate.com.au:skynet/rea-vpc.git"
    }
  ]

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def check!
    check_awscli!
    ensure_rea_vpc
  end

  private

  def check_awscli!
    if which("aws").nil?
      abort "Could not find 'aws' in your path. Please install this to continue."
    end
  end

  def clone(dep)
    logger.info "Cloning #{dep.fetch(:name)}"
    Dir.chdir(DEPS_DIR) do
      `git clone #{dep.fetch(:url)} #{dep.fetch(:name)}`
    end
  end

  def ensure_rea_vpc
    Dir.mkdir(DEPS_DIR) unless Dir.exist?(DEPS_DIR)

    DEPS.each do |dep|
      if Dir.exist?(File.join(DEPS_DIR, dep.fetch(:name)))
        logger.debug "Found #{dep.fetch(:name)}"
      else
        clone(dep)
      end
    end
  end

  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    return nil
  end
end
