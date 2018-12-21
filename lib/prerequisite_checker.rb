require 'logger'

class PrerequisiteChecker
  attr_reader :logger

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def check!
    check_awscli!
    self
  end

  private

  def check_awscli!
    if which("aws").nil?
      abort "Could not find 'aws' in your path. Please install this to continue."
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
  end
end
