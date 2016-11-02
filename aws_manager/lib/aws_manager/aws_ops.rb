require 'aws-sdk'
require 'aws_manager/cloud_formation'
require 'aws_manager/ec2'
require 'aws_manager/util/yaml_loader'

module AwsManager
  class AwsOps
    def initialize(cloudformation = nil, ec2 = nil, autoscaling = nil)
      @cloudformation = cloudformation || CloudFormation.new
      @ec2 = ec2 || Ec2.new
      @autoscaling = autoscaling || AutoScaling.new
    end

    # Get the stack to be backed up filtered by instance id.
    #
    # @param instance_id [String] the instance id
    #
    # @return [Stack] the list of stacks to be backed up.
    def get_stack_of_instance(instance_id)
      stack_name = @ec2.get_tag_value(instance_id, 'aws:cloudformation:stack-name')
      @cloudformation.get_stack(stack_name)
    end

    # Delete back up amis
    #
    # return [Boolean] +true+ if we successfully delete all the back up amis,
    #                  +false+ otherwise.
    def delete_backup_amis
      images = @ec2.retrieve_images.with_owner(:self) \
               .filter('description', "#{@ami_description_prepender}*") \
               .filter('state', 'available')
      flag = true
      images.each do |image|
        flag &&= delete_ami(image) if delete_ami? image
      end
      flag
    end

    # Delete an AMI image
    #
    # @param image [Image] the AMI image to be deleted
    #
    # @return [Boolean] +true+ if it's deleted successfully, +false+ otherwise.
    def delete_ami(image)
      # Get some attributes associated with the AMI before we deregister it.
      image_id = image.image_id
      ec2_image = @ec2.retrieve_images[image_id]
      image_block_devices = ec2_image.block_devices
      image_name = ec2_image.name
      ec2_image.deregister
      while ec2_image.exists?
        puts "image #{image_id} still exist"
        sleep(3)
      end
      flag = true
      image_block_devices.each do |block_device|
        snapshot_id = block_device[:ebs][:snapshot_id]
        puts "Deleting EBS Snapshot #{snapshot_id} which is associated with " \
             "Image #{image_id} (#{image_name})"
        @ec2.retrieve_snapshots[snapshot_id].delete
        flag &&= !@ec2.retrieve_snapshots[snapshot_id].exists?
      end
      flag
    rescue Exception => e
      puts "Deletion of image with id #{image_id} failed e: #{e}."
      true
    end

    # Given an AMI image, determine if the image should be deleted
    #
    # @param image [EC2::Image] the AMI image
    #
    # @return [Boolean] +true+ if the AMI should be removed, +false+ otherwise.
    def delete_ami?(image)
      image_datetime = @ec2.get_image_datetime_stamp(image)
      config = YamlLoader.load_yaml_file_path('resources/config.yml')
      if image.exists?
        keep = BackUp.keep?(image_datetime, config['backup'])
        delete_message = keep ? 'Not deleting' : 'Deleting'
        puts "#{delete_message} Image #{image.image_id} (#{image.name}) with datetimestamp #{image_datetime}"
        !keep
      else
        puts "Image of image id #{image.image_id} does not exist"
        false
      end
    rescue Exception
      puts "Unable to determine whether to delete ami of name #{image.name}."
      false
    end

    # Backup the EC2 instance.
    #
    # @param [String] the instance id
    #
    # @returns [String] the id of the back up AMI.
    def backup_instance
      instance_id = @ec2.retrieve_instance_id
      backup_required = backup?(instance_id)
      return unless backup_required # if backup is not required, return
      ami_id = @ec2.backup_instance(@ec2.retrieve_instances[instance_id])
      stack = get_stack_of_instance(instance_id)
      ami_id if @cloudformation.update_stack_ami_id(stack, ami_id)
    end

    # Whether to backup the instance.
    #
    # @return [Boolean] +true+ if it needs to be backed up, +false+ otherwise.
    def backup?(instance_id)
      fail 'instance_id cannot be nil' if instance_id.nil?

      stack = get_stack_of_instance(instance_id)
      asg_names = @autoscaling.get_group_resources(stack).map(&:physical_resource_id)
      asg_name = @ec2.get_tag_value(instance_id, 'aws:autoscaling:groupName')

      if asg_names.first == asg_name
        instance_ids = @autoscaling.retrieve_instance_ids(asg_name).sort
        if instance_ids.first == instance_id
          true
        else
          puts "instance id #{instance_ids.first} is not the same as #{instance_id}."
          false
        end
      else
        puts "asg #{asg_names.first} is not the same as #{asg_name}."
        false
      end
    end

    # Upload a file to an S3 bucket.
    #
    # @param bucket_name [String] name of the bucket
    # @param bucket_path [String] path within the bucket including file name
    # @param file_path [String] local path of the file to upload
    #
    # @return [Boolean] if the file upload was successful or not.
    def s3_upload_file(bucket_name, bucket_path, file_path)
      file_name = file_path.split('/').last
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(bucket_name).object(bucket_path + file_name)
      obj.upload_file(file_path)
    end

  end
end
