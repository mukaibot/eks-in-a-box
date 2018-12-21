require 'fileutils'

module Commands
  class Generate
    TARGET = 'config.yml'
    SAMPLE = 'templates/config.yml.sample'

    class << self
      def call
        abort("#{TARGET} already exists! Not overwriting.") if File.exists?(TARGET)

        FileUtils.cp SAMPLE, TARGET
        puts "Created #{TARGET}. Please edit as appropriate before creating your cluster!"
      end
    end
  end
end
