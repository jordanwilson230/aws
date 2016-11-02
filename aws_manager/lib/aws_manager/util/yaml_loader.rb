require 'yaml'
require 'aws_manager/errors'
require 'aws_manager/util/file_reader'

module AwsManager
  module Util
    class YamlLoader
      # Will load the YAML string into Hash
      #
      # @param [String] yaml The string that contains the YAML contents
      #
      # @return [Hash] Return the hash read if the YAML string is read successfully
      def self.load_yaml(yaml)
        YAML.load(yaml)
      rescue IOException, StandardError
        raise AwsManager::YAMLLoadError, "Cannot convert to hash from #{yaml}"
      end

      # Will load the YAML file located in the file path
      #
      # @param [String] file_path The path to the YAML file
      #
      # @return [Hash] Return the hash read if the YAML file is read successfully
      def self.load_yaml_file_path(file_path)
        load_yaml(AwsManager::Util::FileReader.read_file_path(file_path))
      rescue IOException, StandardError
        raise AwsManager::FileReadError, "Cannot read from YAML file #{file_path}"
      end
    end
  end
end
