require 'aws-sdk'
require 'aws_manager/util/file_reader'
require 'aws_manager/util/yaml_loader'
require 'aws_manager/util/cf_differ'
require 'aws_manager/cloud_formation_ops'
require 'aws_manager/auto_scaling'
require 'aws_manager/ec2'

module AwsManager
  class CloudFormation
    def initialize(aws_cloud_formation = nil, aws_cloud_formation_resource = nil, autoscaling = nil, ec2 = nil)
      @aws_cloud_formation = aws_cloud_formation || Aws::CloudFormation::Client.new
      @aws_cloud_formation_resource = aws_cloud_formation_resource || Aws::CloudFormation::Resource.new(client: @aws_cloud_formation)
      @autoscaling = autoscaling || AwsManager::AutoScaling.new
      @ec2 = ec2 || AwsManager::Ec2.new
    end

    # Creates a new Cloud Formation Stack using the template and parameters file.
    #
    # @param template_path [String] the template file path that will be used to
    #                               create the Cloud Formation Stack.
    # @param scope_path [String] the path to the YAML file defining the scope
    #                            to operate
    #
    # @return [Stack] the Cloud Formation Stack object that was created.
    def create_stack(template_path, scope_path, hiera_conf, check_status = false, delay = 5, max_attempts = 60)
      template_body = AwsManager::Util::FileReader.read_file_path(template_path)
      template = JSON.parse(template_body)
      param_reader = AwsManager::Util::ParamReader.new(scope_path, hiera_conf)

      stack_name = AwsManager::CloudFormationOps.generate_stack_name(param_reader, template_path)

      required_params = AwsManager::CloudFormationOps.get_required_parameters(param_reader, template)

      response = @aws_cloud_formation.create_stack(
        stack_name: stack_name,
        template_body: template_body,
        parameters:  required_params,
        capabilities: ['CAPABILITY_IAM']
      )

      wait_for_status(
        :stack_create_complete,
        { stack_name: stack_name },
        delay,
        max_attempts,
        method(:default_before_wait_callback)) if check_status

      response[0]

    rescue Aws::CloudFormation::Errors::AlreadyExistsException
      stack_status = retrieve_stack_status(stack_name)
      puts "Current existing stack status: [#{stack_status}]."
      raise
    end

    # List all CloudFormation Stacks
    # @param stack_status_codes [Array[String]] the StackStatus codes to filter stacks on
    #                                           the method will list all stacks with
    #                                           status codes from the list
    #                                           Defaults to ['CREATE_COMPLETE']
    def list_stacks(stack_status_codes = ['CREATE_COMPLETE'])
      @aws_cloud_formation.list_stacks(stack_status_filter: stack_status_codes).stack_summaries.map { |row| row[:stack_name] }
    end

    # Deletes a Cloud Formation Stack, deducing the name from the template and parameters file.
    #
    # @param template_path [String] the template file path that will be used to
    #                               delete the Cloud Formation Stack.
    # @param scope_path [String] the path to the YAML file defining the scope
    #                            to operate
    #
    # @return [String] the name of the deleted Cloud Formation Stack.
    def delete_stack(template_path, scope_path, hiera_conf, check_status = false, delay = 5, max_attempts = 60)
      param_reader = AwsManager::Util::ParamReader.new(scope_path, hiera_conf)

      stack_name = AwsManager::CloudFormationOps.generate_stack_name(param_reader, template_path)
      status = retrieve_stack_status(stack_name)
      puts "Current stack status: #{status}"

      stack = get_stack(stack_name)
      stack.delete
      wait_for_status(
        :stack_delete_complete,
        { stack_name: stack_name },
        delay,
        max_attempts,
        method(:default_before_wait_callback)) if check_status

      stack_name
    end

    # Validates the template file located in file path with Cloud Formation.
    #
    # @param template_path [String] the file path of the template file
    #
    # @return [Boolean] +true+ if it passes validation, +false+ otherwise.
    def validate_template_file(template_path)
      validate_template(AwsManager::Util::FileReader.read_file_path(template_path))
      rescue FileReadError => fre
        raise fre
    end

    # Validates the template with Cloud Formation.
    #
    # @param template[String] the template to be validated
    #
    # @return [Boolean] +true+ if it passes validation, +false+ otherwise.
    def validate_template(template)
      @aws_cloud_formation.validate_template(template_body: template)
    rescue Exception => e
      puts e
      false
    end

    # Retrieve the Cloud Formation stack by name.
    #
    # @param name [String] the name of the stack we wish to retrieve
    #
    # @return [Stack] the Cloud Formation stack that's retrieved.
    def get_stack(name)
      @aws_cloud_formation_resource.stack(name)
    end

    # Back up all the AMIs within the stack.
    #
    # @param stack [Stack] the stack we want to back up
    #
    # @return [Boolean] +true+ if stack is successfully backup, +false+ otherwise.
    def backup_stack(stack)
      fail 'stack cannot be nil' if stack.nil?
      asg_name = @autoscaling.get_group_resources(stack).first.physical_resource_id
      ec2_instance_id = @autoscaling.get_group(asg_name).auto_scaling_instances \
                        .first.instance_id
      ec2_instance = @ec2.retrieve_instances[ec2_instance_id]

      puts "Backing up ec2 instance with id #{ec2_instance_id}"
      ami_image_id = @ec2.backup_instance(ec2_instance)
      puts "Back up complete for #{ec2_instance_id}; image_id: #{ami_image_id}, updating stack parameters."
      true
    end

    # Update the AMI id of a CloudFormation stack
    #
    # @param stack [Stack] the stack we want to update
    # @param ami_id [String] the new ami id
    #
    # @return [Boolean] +true+ if update of ami id is successful, +false+ otherwise.
    def update_stack_ami_id(stack, ami_id)
      puts "Updating stack of name #{stack.name} with Parameter BaseAmiId=#{ami_id}."
      # Change the AMI image id and update the Cloud Formation stack
      parameters = stack.parameters
      parameters['BaseAmiId'] = ami_id
      stack.update(
        template: stack.template,
        parameters: parameters)
      puts 'Stack parameters update complete.'

      wait_for_status(
        :stack_update_complete,
        { stack_name: stack.stack_name },
        10,
        60,
        method(:default_before_wait_callback))
      true
    end

    # Update a CloudFormation stack
    # Structural update affecting both template and parameters
    # @param stack_name [String] the name of the stack we want to update
    # @param force_update [Boolean] whether to update stack without diffs checking
    # @param check_status [Boolean] whether to check for the status of the update
    # @param template_path [String] the template file path that will be used to
    #                               update the Cloud Formation Stack.
    # @param scope_path [String] the path to the YAML file defining the scope
    #                            to operate
    # @param force_update [Boolean] whether to update stack without diffs checking
    # @param ignore_params [Array] List of parameters to ignore
    # @param check_status [Boolean] whether to check for the status of the update
    # @param delay [Integer] the delay between checks
    # @param max_attempts [Integer] the maximum number of attempts to check
    #
    # @return [Stack] the Cloud Formation Stack object that was updated.
    def update_stack(stack_name, template_path, scope_path, hiera_conf, force_update = false, ignore_params = [], check_status = false, delay = 5, max_attempts = 60)
      local_template_body = AwsManager::Util::FileReader.read_file_path(template_path).chomp
      template = JSON.parse(local_template_body)
      param_reader = AwsManager::Util::ParamReader.new(scope_path, hiera_conf)

      stack_name_check = AwsManager::CloudFormationOps.generate_stack_name(param_reader, template_path)

      # Raise an exception if existing stack name does not match the generated stack name.
      # You may consider creating a different stack when the names do not match.
      fail AwsManager::CloudFormationError, 'Stack name must match generated stack name' if stack_name != stack_name_check

      required_params = AwsManager::CloudFormationOps.get_required_parameters(param_reader, template)

      # Check for diffs.
      unless force_update
        remote_template_body = @aws_cloud_formation.get_template(stack_name: stack_name).template_body.chomp
        template_diffs_found = AwsManager::Util::CloudFormationDiffer.diff_templates(remote_template_body, local_template_body)

        remote_params = get_stack(stack_name).parameters

        parameters_diffs_found = AwsManager::Util::CloudFormationDiffer.diff_params(remote_params, required_params, ignore_params)
        if template_diffs_found || parameters_diffs_found
          fail AwsManager::CloudFormationError, "Templates and/or parameters diffs found as per above. Use --force-update true /or --ignore-params 'param_key' if you are certain about the changes"
        end
      end

      response = @aws_cloud_formation.update_stack(
        stack_name: stack_name,
        use_previous_template: false,
        template_body: local_template_body,
        parameters: required_params,
        capabilities: ['CAPABILITY_IAM']
      )

      wait_for_status(
        :stack_update_complete,
        { stack_name: stack_name },
        delay,
        max_attempts,
        method(:default_before_wait_callback)) if check_status

      response[0]
    end

    # Loads a stack based on it's name or it's unique ID and extracts the outputs hash
    # @param stack_name [String] The name or the unique ID of the stack
    #
    # @return [String] the outputs hash converted to JSON
    def describe_stack_outputs(stack_name)
      response = @aws_cloud_formation.describe_stacks(stack_name: stack_name)
      response.stacks[0].outputs.collect { |item| { key: item.output_key, value: item.output_value } }.to_json
    end

    # Loads a stack based on it's name or it's unique ID and extracts the outputs hash. Captures the items in the
    # outputs hash to the YAML file provided.
    # @param stack_name [String] The name or the unique ID of the stack
    # @param yaml_file_path [String] The fully qualified path to the YAML file.
    # @param items_to_extract If supplied, keys found in this array would only be written to the YAML file.
    #
    # @return [String] the outputs hash
    def capture_stack_outputs(stack_name, yaml_file_path, items_to_extract = nil)
      response = @aws_cloud_formation.describe_stacks(stack_name: stack_name)
      outputs = response.stacks[0].outputs.collect { |item| { key: item.output_key, value: item.output_value } }
      data = AwsManager::Util::YamlLoader.load_yaml_file_path(yaml_file_path)
      if items_to_extract.nil?
        outputs.each do |item|
          # apped to YAML file
          data[item[:key]] = item[:value]
        end
      else
        outputs.each do |item|
          if items_to_extract.include?(item[:key])
            # only update value if key found
            data[item[:key]] = item[:value]
          end
        end
      end

      # Dumps the YAML output hash into the YAML file specified
      File.open(yaml_file_path, 'w+') { |f| YAML.dump(data, f) }

      outputs
    end

    # Retrieves the current status for a stack based on the stack's name
    # @param stack_name [String] The name of the stack
    #
    # @return [String] the stack current status as string
    def retrieve_stack_status(stack_name)
      @aws_cloud_formation.describe_stacks(stack_name: stack_name)[0][0].stack_status
    rescue Aws::CloudFormation::Errors::ValidationError
      puts 'Stack not found.'
      raise
    end

    private

    # Wait for a certain status to be achieved on waiter
    # @param waiter_name [Symbol] The name of the Waiter
    #                             Options: :stack_create_complete, :stack_delete_complete, :stack_update_complete
    #                             Waiter docs: http://docs.aws.amazon.com/sdkforruby/api/Aws/Waiters/Waiter.html
    # @param parameters [Hash] Parameters for the CloudFormation::Client::wait_until
    #                          Method docs: http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Client.html#wait_until-instance_method
    # @param before_wait_callback [Method] The callback method to be called before wait on the Waiter.
    # @param before_attempt_callback [Method] The callback method to be called before attempt on the Waiter.
    # @param delay [Int] How often to query AWS CloudFormation for the status.
    # @param max_attempts [Int] The number of max_attempts.
    #
    # @return [Boolean] true if the status matches the expected status in the given timeframe
    #                   false if the stack has reached a different terminal status or does not reach the @param expected_status
    def wait_for_status(
      waiter_name,
      parameters,
      delay = 5,
      max_attempts = 60,
      before_wait_callback = ->(_) { true },
      before_attempt_callback = ->(_) { true })

      @aws_cloud_formation.wait_until(waiter_name, parameters) do |waiter|
        waiter.max_attempts = max_attempts
        waiter.delay = delay
        before_wait_callback.call(waiter)
        before_attempt_callback.call(waiter)
      end

    rescue Aws::CloudFormation::Errors::FailureStateError,
           Aws::CloudFormation::Errors::TooManyAttemptsError,
           Aws::CloudFormation::Errors::UnexpectedError,
           Aws::CloudFormation::Errors::NoSuchWaiterError => e
      raise AwsManager::CloudFormationError, e.message
    end

    private

    def default_before_wait_callback(waiter)
      waiter.before_wait do |attempts, response|
        status = response[0][0].stack_status
        puts "Current stack status: [#{status}]."
        puts "Attempts left: #{waiter.max_attempts - attempts} with delay of #{waiter.delay} seconds."
        STDOUT.flush
      end
    end
  end
end
