require 'fileutils'
require 'aws_manager/errors'

module AwsManager
  module Util
    class FileReader
      # Will read a text file into string given a file path
      #
      # @param [String] file_path The path to the file to be loaded
      #
      # @return [String] Return the text in the file
      def self.read_file_path(file_path)
        File.read(file_path)
      rescue StandardError
        raise AwsManager::FileReadError, "Cannot read from file #{file_path}"
      end
    end
  end
end
