require 'json'
require 'fileutils'

module AwsManager
  class CloudFormationOps
    # Given a the parameters hash and a template file name, return the component
    # name.
    #
    # @param param_reader [AwsManager::Util::ParamReader] the parameter reader
    #                                                     instance
    #
    # @param template_filename [String] the name of the template file.
    #
    # @return [String] the name of the component.
    def self.get_component_name(param_reader, template_filename)
      generic_prefix = 'generic_customer'

      parameters = param_reader.scope

      unless self.valid_parameters?(parameters)
        fail 'Scope used failed validation. Missing Environment, Customer and/or Project.'
      end

      unless self.valid_scope?(param_reader)
        fail 'Scope used failed validation. Scope parameters do not match those inside inventory'
      end

      unless self.valid_template_filename?(template_filename, parameters)
        fail 'Template file name failed validation.'
      end

      template_file_name_copy = template_filename
      if template_file_name_copy.match(/^#{generic_prefix}/)
        template_file_name_copy.gsub!(/^#{generic_prefix}/, '')
      else
        template_file_name_copy.gsub!(parameters['Customer'], '')
        template_file_name_copy.gsub!(parameters['Project'], '')
      end
      template_file_name_copy.gsub!(/^(_)+/, '')
      template_file_name_copy.gsub!(/(_)+/, '-')

      template_file_name_copy
    end

    # This will given the CloudFormation parameters hash, validate that the
    # required KVP's are present. The required KVP's are:
    # * Environment
    # * Customer
    # * Project
    #
    # @param parameters [Hash] the CloudFormation parameters hash
    #
    # @return [Boolean] +true+ if it passes validation, +false+ otherwise.
    def self.valid_parameters?(parameters)
      environment = parameters['Environment']
      customer = parameters['Customer']
      project = parameters['Project']

      !(environment.nil? || customer.nil? || project.nil?)
    end

    # Validates if the file name of the template is in valid format.
    #
    # @param filename [String] the name of the template file.
    # @param parameters [Hash] the CloudFormation parameters hash that consists
    #                          of at least :"Environment", :"Customer" and
    #                          :"Project"
    #
    # @return [Boolean] +true+ if it passes validation, +false+ otherwise.
    def self.valid_template_filename?(filename, parameters)
      customer = parameters['Customer']
      project = parameters['Project']
      generic_prefix = 'generic_customer'

      (filename.include? generic_prefix) ||
        (filename.include?(customer) && filename.include?(project))
    end

    # Validates the scope selected and the resulting parameters found inside
     # the hiera inventory
     #
     # @param param_reader [AwsManager::Util::ParamReader] the parameter reader
     #                                                     instance
     #
     # @return [Boolean] +true+ if it passed validation, +false+ otherwise
     def self.valid_scope?(param_reader)
       param_reader.scope.map { |key,value| value == param_reader.lookup(key) }.inject(true){|sum, x| sum && x}
     end

    # Given the parameters hash and the template hash, returns the list of
    # required parameters.
    #
    # @param param_reader [AwsManager::Util::ParamReader] the parameter reader
    #                                                     instance
    # @param template [Hash] the hash we parsed from the template file
    #
    # @return [Hash] Returns the list of required parameters.
    def self.get_required_parameters(param_reader, template)
      required_parameters = []
      missing_parameters = []

      template['Parameters'].each do |key, value|
      parameters = param_reader.lookup(key)
        if !parameters.nil?
          parameter_hash = {
            'parameter_key' => key,
            'parameter_value' => parameters,
            'use_previous_value' => false
          }
          required_parameters.push(parameter_hash)
        elsif !value.key?('Default') || value['Default'].empty?
          missing_parameters.push(key)
        end
      end

      fail 'The following parameters are required and have no default ' \
            "values: #{missing_parameters}." unless missing_parameters.empty?

      required_parameters
    end

    # Generate the name of the stack.
    #
    # @param param_reader [AwsManager::Util::ParamReader] the parameter reader
    #                                                     instance
    # @param template_filepath [String] the path to the template file, we expect
    #                                   it to at least contain the value of
    #                                   "Customer", "Project", "Component"
    #                                   separated by "_"
    #
    # @return [String] the name of the stack generate.
    def self.generate_stack_name(param_reader, template_filepath)
      filename = File.basename(template_filepath, File.extname(template_filepath))
      component_name = get_component_name(param_reader, filename)

      parameters = param_reader.scope

      "#{parameters['Environment']}-#{parameters['Customer']}-" \
      "#{parameters['Project']}-#{component_name}"
    end
  end
end
