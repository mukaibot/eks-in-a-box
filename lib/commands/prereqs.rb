require 'prereqs/checker'
require 'prereqs/client_binary_installer'

module Commands
  class Prereqs
    class << self
      def call
        ::Prereqs::Checker.new.check!
        ::Prereqs::ClientBinaryInstaller.new(PLATFORM).call
      end
    end
  end
end
