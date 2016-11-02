require 'hiera'
require 'puppet'
require 'aws_manager/util/yaml_loader'

module AwsManager
  module Util
    # @attr_reader scope [Hash] the facts to use
    class ParamReader
      attr_reader :scope

      # initialize the class
      # @param config [String] the yaml config file containing the scope
      # @param hiera_conf [String] the hiera.yaml conf file
      def initialize(config, hiera_conf)
        @scope = AwsManager::Util::YamlLoader.load_yaml_file_path(config)
        hiera_config = Hiera::Config.load(hiera_conf)
        hiera_config[:logger] = 'noop'

        @hiera = Hiera.new(:config => hiera_config)
      end

      # Lookup a parameter from the config
      # @param name [String] the name of the parameter to lookup
      # @return [String|nil] the lookup value
      def lookup(name)
        @hiera.lookup(name, nil, @scope)
      end
    end
  end
end
