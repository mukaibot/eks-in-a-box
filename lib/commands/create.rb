require 'client_binary_installer'
require 'create/eks_creator'
require 'prerequisite_checker'

module Commands
  class Create
    class << self
      def call(config, logger)
        PrerequisiteChecker.new.check!
        ClientBinaryInstaller.new(PLATFORM).call

        if config.valid?
          ::Create::EksCreator.new(config, logger).call
        else
          logger.fatal "Missing values for #{config.missing_attributes.join(', ')}"
          exit 1
        end
      end
    end
  end
end
