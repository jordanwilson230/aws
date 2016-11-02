require 'thor'
require 'aws-sdk'
require 'aws_manager/cloud_formation'
require 'aws_manager/aws_ops'
require 'aws_manager/errors'
require 'aws_manager/route53'
require 'aws_manager/ec2'
require 'aws_manager/util/param_reader'
require 'aws_manager/util/validators'
require 'aws_manager/util/printers'
require 'aws_manager/version'

module AwsManager
  module Cli
    class Application < Thor
      desc 'version', 'Prints version and exits'
      def version
        v = AwsManager::VERSION
        say "AWS Manager #{v}.", :yellow
      end

      desc 'cf-create-stack', 'Manages CloudFormation stack creation'
      method_option :scope, required: true, desc: 'YAML file defining the scope to operate'
      method_option :hiera_conf, required: true, desc: 'Path to hiera.yaml configuration file'
      method_option :cfn_template, required: true, desc: 'JSON file containing the CloudFormation template'
      method_option :check_status, type: :boolean, default: false, desc: 'Check status flag. Default false. When set true, query stack status.'
      method_option :delay, default: 5, desc: 'How often to retry checking the status'
      method_option :max_attempts, default: 60, desc: 'The number of max_attempts when expecting a status.'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def cf_create_stack
        say 'Attempting to create CloudFormation stack', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        param_reader = AwsManager::Util::ParamReader.new(options[:scope], options[:hiera_conf])
        scope = param_reader.scope.to_s
        say "Using scope #{scope}", :cyan

        cloud_formation = AwsManager::CloudFormation.new
        stack_id = cloud_formation.create_stack(
          options[:cfn_template],
          options[:scope],
          options[:hiera_conf],
          options[:check_status],
          options[:delay],
          options[:max_attempts]
        )
        say "CloudFormation Stack created successfully with id: #{stack_id}", :green

        rescue FileReadError => fre
          say "#{fre}", :red
          # TODO: Log error details
        rescue YAMLLoadError => yle
          say "#{yle}", :red
          # TODO: Log error details
        rescue Aws::Errors::MissingCredentialsError => mce
          say "#{mce}", :red
          # TODO: Log error details
        rescue Aws::CloudFormation::Errors::InvalidClientTokenId => icti
          say "#{icti}", :red
          # TODO: Log error details
        rescue Aws::CloudFormation::Errors::AlreadyExistsException => aee
          say "#{aee}", :yellow
      end

      desc 'cf-update-stack', 'Updates the supplied stack with the new CloudFormation template and the parameters values provided'
      method_option :stack_name, required: true, desc: 'The name of the stack to be updated'
      method_option :cfn_template, required: true, desc: 'JSON file containing the CloudFormation template'
      method_option :scope, required: true, desc: 'YAML file defining the scope to operate'
      method_option :hiera_conf, required: true, desc: 'Path to hiera.yaml configuration file'
      method_option :force_update, type: :boolean, default: false, desc: 'Force update regardless of diffs.'
      method_option :ignore_params, type: :array, default: [], desc: 'List of parameters to ignore on diffs.'
      method_option :check_status, type: :boolean, default: false, desc: 'Check status flag. Default false. When set true, query stack status.'
      method_option :delay, default: 5, desc: 'How often to retry checking the status'
      method_option :max_attempts, default: 60, desc: 'The number of max_attempts when expecting a status.'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def cf_update_stack
        say 'Attempting to update a CloudFormation stack', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        param_reader = AwsManager::Util::ParamReader.new(options[:scope], options[:hiera_conf])
        scope = param_reader.scope.to_s
        say "Using scope #{scope}", :cyan

        cloud_formation = AwsManager::CloudFormation.new
        stack_id = cloud_formation.update_stack(
          options[:stack_name],
          options[:cfn_template],
          options[:scope],
          options[:hiera_conf],
          options[:force_update],
          options[:ignore_params],
          options[:check_status],
          options[:delay],
          options[:max_attempts]
        )
        say "Stack update successful with id: #{stack_id}", :green

        rescue FileReadError => fre
          say "#{fre}", :red # TODO: Log error details
        rescue YAMLLoadError => yle
          say "#{yle}", :red # TODO: Log error details
        rescue Aws::Errors::MissingCredentialsError => mce
          say "#{mce}", :red # TODO: Log error details
        rescue Aws::CloudFormation::Errors::InvalidClientTokenId => icti
          say "#{icti}", :red
        rescue Aws::CloudFormation::Errors::ValidationError => ve
          say "#{ve}", :red # TODO: Log error details
        rescue RuntimeError => rte
          say "#{rte}", :red
      end

      desc 'cf-list-stacks', 'Lists CloudFormation stacks'
      method_option :stack_status_codes, type: :array, default: ['CREATE_COMPLETE'], desc: 'The status codes to filter stacks on.'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def cf_list_stacks
        say 'Attempting to list CloudFormation stacks', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        cloud_formation = AwsManager::CloudFormation.new
        stack_names = cloud_formation.list_stacks(options[:stack_status_codes])
        say 'CloudFormation Stacks listed successfully', :green
        say "#{stack_names}", :green

        rescue Aws::Errors::MissingCredentialsError => mce
          say "#{mce}", :red # TODO: Log error details
        rescue Aws::CloudFormation::Errors::InvalidClientTokenId => icti
          say "#{icti}", :red # TODO: Log error details
      end

      desc 'cf-delete-stack', 'Deletes CloudFormation stack'
      method_option :scope, required: true, desc: 'YAML file defining the scope to operate'
      method_option :hiera_conf, required: true, desc: 'Path to hiera.yaml configuration file'
      method_option :cfn_template, required: true, desc: 'JSON file containing the CloudFormation template'
      method_option :check_status, type: :boolean, default: false, desc: 'Check status flag. Default false. When set true, query stack status.'
      method_option :delay, default: 5, desc: 'How often to retry checking the status'
      method_option :max_attempts, default: 60, desc: 'The number of max_attempts when expecting a status.'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def cf_delete_stack
        say 'Attempting to delete CloudFormation stack', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        param_reader = AwsManager::Util::ParamReader.new(options[:scope], options[:hiera_conf])
        scope = param_reader.scope.to_s
        say "Using scope #{scope}", :cyan

        cloud_formation = AwsManager::CloudFormation.new
        deleted_stack_name = cloud_formation.delete_stack(
          options[:cfn_template],
          options[:scope],
          options[:hiera_conf],
          options[:check_status],
          options[:delay],
          options[:max_attempts]
        )
        say "CloudFormation Stack #{deleted_stack_name} deleted successfully", :green

        rescue FileReadError => fre
          say "#{fre}", :red
          # TODO: Log error details
        rescue YAMLLoadError => yle
          say "#{yle}", :red
          # TODO: Log error details
        rescue Aws::Errors::MissingCredentialsError => mce
          say "#{mce}", :red
          # TODO: Log error details
        rescue Aws::CloudFormation::Errors::InvalidClientTokenId => icti
          say "#{icti}", :red
          # TODO: Log error details
        rescue Aws::CloudFormation::Errors::ValidationError => ve
          say "#{ve}", :yellow
      end

      desc 'cf-validate-stack', 'Validates the supplied template file with Cloud Formation'
      method_option :cfn_template, required: true, desc: 'JSON file containing the CloudFormation template'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def cf_validate_stack
        say 'Attempting to validate a template with CloudFormation', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        cloud_formation = AwsManager::CloudFormation.new
        if cloud_formation.validate_template_file(options[:cfn_template])
          say 'Template validation successful.', :green
        else
          say 'Template validation unsuccessful.', :red
        end

        rescue FileReadError => fre
          say "#{fre}", :red # TODO: Log error details
        rescue YAMLLoadError => yle
          say "#{yle}", :red # TODO: Log error details
        rescue Aws::Errors::MissingCredentialsError => mce
          say "#{mce}", :red # TODO: Log error details
        rescue Aws::CloudFormation::Errors::InvalidClientTokenId => icti
          say "#{icti}", :red # TODO: Log error details
      end

      desc 'ec2-backup-amis', 'Gets a list of all instances with \'Backup=true\' and backs them up'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def ec2_backup_amis
        say 'UNTESTED METHOD; PROCEED WITH CAUTION', :red
        say "Attempting to backup all instances with \'Backup=true\'", :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        aws_ops = AwsManager::AwsOps.new
        ami_id = aws_ops.backup_instance

        say "Successfully created an AMI #{ami_id}", :green
      end

      desc 'ec2-delete-amis', 'Deletes all backup AMIs'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def ec2_delete_amis
        say 'UNTESTED METHOD; PROCEED WITH CAUTION', :red
        say 'Attempting to delete all backup AMIs', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        aws_ops = AwsManager::AwsOps.new
        result = aws_ops.delete_backup_amis

        if result
          say 'Successfully deleted all backup AMIs', :green
        else
          say 'Some backup AMIs could not be deleted!', :red
        end
      end

      desc 'ec2-attach-volume', 'Attaches an EBS volume to an EC2 instance.'
      method_option :volume_id, required: true, desc: 'The volume to attach. It must be on the same Availability Zone (AZ) as the EC2 instance.'
      method_option :instance_id, required: true, desc: 'The instance where the volume needs to be attached.'
      method_option :device, required: true, desc: "The device mount point. It should be of the form '/dev/sdh/' or 'xvdh'."
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def ec2_attach_volume
        say "Attempting to attach an EBS volume #{options[:volume_id]} to an EC2 instance #{options[:instance_id]}", :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        ec2 = AwsManager::Ec2.new
        result = ec2.attach_ebs_volume(options[:volume_id], options[:instance_id], options[:device])
        say 'Successfully completed attaching the EBS volume', :green
        say "#{result}", :green
      end

      desc 'route53-create-record', 'Create a Route53 record set using the parameters provided. If the record already exists then modify it.'
      method_option :hosted_zone_id, required: true, desc: 'The existing hosted zone id to be used for creating the record set'
      method_option :domain_name, required: true, desc: 'The existing domain name to be used for creating the record set'
      method_option :record_name, required: true, desc: 'The name of the record set to create or modify'
      method_option :interface, required: true, desc: 'The type of network interface to be used for creating the record set'
      method_option :ttl, default: 300, desc: 'the TTL to use for the record'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def route53_create_record
        say 'Attempting to create or delete a Record Set in Route53', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        route53 = AwsManager::Route53.new
        result = route53.change_record_set(
          'UPSERT',
          options[:hosted_zone_id],
          options[:domain_name],
          options[:record_name],
          options[:interface],
          options[:ttl])
        say 'Successfully completed UPSERT of Route53 record', :green
        say "#{result}", :green
      end

      desc 'describe-stack-outputs', 'Extracts the outputs hash of a stack based on the name or ID.'
      method_option :stack_name, required: true, desc: 'The name or unique ID of the stack'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def describe_stack_outputs
        say 'Attempting to find the stack', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        cloud_formation = AwsManager::CloudFormation.new
        outputs = cloud_formation.describe_stack_outputs(options[:stack_name])

        if outputs.length > 0
          puts outputs
        else
          say "No outputs defined for stack: #{options[:stack_name]}", :red
        end

        rescue Aws::CloudFormation::Errors::ValidationError => ve
          say "#{ve}", :red # TODO: Log error details
      end

      desc 'capture-stack-outputs', 'Captures all or specific items from the outputs hash of a CloudFormation stack in the given YAML file.'
      method_option :stack_name, required: true, desc: 'The name or unique ID of the stack'
      method_option :yaml_file_path, required: true, desc: 'The fully qualified path to the existing YAML file. If file not found, this is not going to create it.'
      method_option :items_to_extract, type: :array, desc: 'White-space separated array of items keys to be extracted from the outputs hash.'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def capture_stack_outputs
        say "Attempting to find the stack #{options[:stack_name]}", :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        cloud_formation = AwsManager::CloudFormation.new
        outputs = cloud_formation.capture_stack_outputs(options[:stack_name], options[:yaml_file_path], options[:items_to_extract])

        if outputs.length > 0
          say "#{outputs}", :green
          say "Captured in #{options[:yaml_file_path]}", :yellow
        else
          say "No outputs defined for stack: #{options[:stack_name]}", :red
        end

        rescue FileReadError => fre
          say "#{fre}", :red # TODO: Log error details
        rescue Aws::CloudFormation::Errors::ValidationError => ve
          say "#{ve}", :red # TODO: Log error details
      end

      desc 'retrieve-stack-status', 'Show the current status of the stack based on stack name'
      method_option :stack_name, required: true, desc: 'The name or unique ID of the stack'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def retrieve_stack_status
        say 'Attempting to find the stack', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        cloud_formation = AwsManager::CloudFormation.new
        status = cloud_formation.retrieve_stack_status(options[:stack_name])
        puts status
        rescue Aws::CloudFormation::Errors::ValidationError => ve
          say "#{ve}", :red # TODO: Log error details
      end

      desc 's3-upload', 'Upload files to an S3 bucket.'
      method_option :file, :aliases => '-f', desc: 'File you want to upload.'
      method_option :bucket, :aliases => '-b', desc: 'Name of the bucket you want to upload to.'
      method_option :bucket_path, :aliases => '-p', default: '', desc: 'Path or Key to upload to. HINT: start with the folder and end with a `/` e.g. `my/folder/`'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, :aliases => '-r', default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def s3_upload
        say "Uploading `#{options[:file]}` to `#{options[:bucket]}#{options[:bucket_path]}`...", :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        aws_ops = AwsManager::AwsOps.new
        upload_success = aws_ops.s3_upload_file(options[:bucket], options[:bucket_path], options[:file])

        if upload_success
          say "Uploaded successfully!", :green
        else
          say "Upload failed, please try again.", :red
        end

        rescue FileReadError => fre
          say "#{fre}", :red # TODO: Log error details
        rescue Exception => e
          say "#{e}", :red # TODO: Log error details
      end

      desc 'route53-cleanup', 'Cleanup orphan Route53 recordsets in a specific hosted zone'
      method_option :hosted_zone_name, :aliases => '-h', required: true, desc: 'Targeted hosted zone for cleanup'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, :aliases => '-r', default: 'eu-west-1', desc: 'AWS region to use while connecting to Route53.'
      def route53_cleanup
        say 'Attempting to delete orphan record sets in Route53', :green
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])
        route53 = AwsManager::Route53.new
        zone_id = route53.get_zone_id_by_name(options[:hosted_zone_name])
        records = route53.get_a_recordsets(zone_id)

        ec2 = AwsManager::Ec2.new
        regions = ec2.ec2_regions
        ips = regions.inject([]) do |ips, region|
          say "Switch to Region: #{region} to get list of ip addresses of all EC2 instances", :green
          ec2 = AwsManager::Ec2.new(Aws::EC2::Client.new(region: region))
          ips << ec2.ec2_ips
        end.flatten
        orphans = records.reject { |record| ips.include?(record.resource_records.first.value) }
        if orphans.empty?
          say 'No orphans found, have a good day -_-', :green
        else
          orphans.each do |orphan|
            say "Deleting orphan #{orphan.name} => #{orphan.resource_records.first.value}", :red
            result = route53.delete_recordset(zone_id, orphan.to_h)
            say "#{result.to_h}", :green
          end
        end
      end

      desc 'check-reserved', 'Check any remaining capacity for reserved instances'
      method_option :instance_types, :aliases => '-i', default: '', desc: 'Type of instance to check as a comma separated list e.g. t2.micro OR t2.micro,m3.medium'
      method_option :aws_access_key, desc: 'Access key of the AWS account'
      method_option :aws_secret_key, desc: 'Secret key of the AWS account'
      method_option :aws_region, :aliases => '-r', default: 'eu-west-1', desc: 'AWS region to use while connecting to CloudFormation.'
      def check_reserved
        say "Checking reserved instance usage...", :green

        # Validate the instances
        options[:instance_types].split(',').each{ |type| AwsManager::Util::Validators.instance_type(type) }
        set_aws_config(options[:aws_access_key], options[:aws_secret_key], options[:aws_region])

        # Fetch filtered information from AWS
        ec2 = AwsManager::Ec2.new
        reservedInstances = ec2.check_reserved_instances(options[:instance_types])
        runningInstances = ec2.describe_instances(options[:instance_types])
        runningSpotInstances = ec2.describe_instances(options[:instance_types], spot_instances=true)

        # Group by AZ
        runningInstancesByAZ = runningInstances.group_by{ |i| i[0].placement.availability_zone }.to_h
        runningSpotInstancesByAZ = runningSpotInstances.group_by{ |i| i[0].placement.availability_zone }.to_h
        reservedInstancesByAZ = reservedInstances.group_by{ |i| i.availability_zone }.to_h

        # Calculate counts by instance types
        runningInstanceCountByAZ = runningInstancesByAZ.map{ |az,i|
          [az, i.group_by{ |j| j[0].instance_type }.map{ |k,v| [k, v.length] }.to_h]
        }.to_h
        runningSpotInstanceCountByAZ = runningSpotInstancesByAZ.map{ |az,i|
          [az, i.group_by{ |j| j[0].instance_type }.map{ |k,v| [k, v.length] }.to_h]
        }.to_h
        reservedInstanceCountByAZ = reservedInstancesByAZ.map{ |az,i|
          [az, i.group_by{ |j| j.instance_type }.map{ |k,v| [k, v.map{|w| w.instance_count}.inject(0){|sum,x| sum + x } ] }.to_h]
        }.to_h

        # Identify zones and instances
        availableAZs = [runningInstanceCountByAZ.keys, runningSpotInstancesByAZ.keys, reservedInstanceCountByAZ.keys].flatten.to_set
        availableInstancesByAZ = availableAZs.map{ |az|
          [az, [runningInstanceCountByAZ.fetch(az).keys, runningInstanceCountByAZ.fetch(az).keys, reservedInstanceCountByAZ.fetch(az).keys].flatten.to_set]
        }.to_h

        # Loop and print
        availableInstancesByAZ.keys.each{ |az|
          say "\n" # Pretty spacing
          availableInstancesByAZ.fetch(az).each{|instanceType|
            reservedCount = reservedInstanceCountByAZ.fetch(az, { az => {instanceType => 0} }).fetch(instanceType, 0)
            runningCount = runningInstanceCountByAZ.fetch(az, { az => {instanceType => 0} }).fetch(instanceType, 0)
            spotCount = runningSpotInstanceCountByAZ.fetch(az, { az => {instanceType => 0} }).fetch(instanceType, 0)
            AwsManager::Util::Printers.output_reserved_format(az, instanceType, runningCount, reservedCount, spotCount)
          }
        }

        rescue AwsManager::Util::Validators::InstanceTypeError => ite
          say "InstanceTypeError: #{ite}", :red
        rescue Error => e
          say "Unknown error occured. #{e}", :red
      end

      private

      # Sets global configuration for the `aws-sdk` gem.
      #
      # @param aws_access_key (String)  AWS access key id credential.
      # @param aws_secret_key (String)  AWS secret access key credential.
      # @param aws_region (String)      AWS region.
      #
      def set_aws_config(aws_access_key = nil, aws_secret_key = nil, aws_region)
        say "Using region:#{aws_region}", :yellow
        Aws.config[:region] = aws_region
        say "Using aws_access_key=#{aws_access_key}", :yellow if aws_access_key
        say "Using aws_secret_key=#{aws_secret_key}", :yellow if aws_secret_key
        Aws.config[:credentials] = Aws::Credentials.new(aws_access_key, aws_secret_key) if aws_access_key && aws_secret_key
      end
    end
  end
end
