require 'logger'

module Prereqs
  class Checker
    attr_reader :logger

    def initialize
      @logger = Logger.new(STDOUT)
    end

    def check!
      check_awscli!
      check_curl!
      self
    end

    private

    def check_awscli!
      if which("aws").nil?
        abort "Could not find 'aws' in your path. Please install this to continue."
      end
    end

    def check_curl!
      if which("curl").nil?
        abort "Could not find 'curl' in your path. Please install this to continue."
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
end
