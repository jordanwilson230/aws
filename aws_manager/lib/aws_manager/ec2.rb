require 'aws-sdk'

module AwsManager
  class Ec2
    def initialize(aws_ec2 = nil)
      @aws_ec2 = aws_ec2 || Aws::EC2::Client.new
      @ami_description_prepender = 'Automated AMI Creation'
    end

    # Retrieve the collection of Amazon EC2 instances.
    #
    # @param instance_id [String] the id of the EC2 instance
    #
    # @return [InstanceCollection] the collection of EC2 instances with the
    #                              specified instance id.
    def retrieve_instances
      @aws_ec2.instances
    end

    # Get the current EC2 instance id.
    #
    # @return [String] the instance id.
    def retrieve_instance_id
      url = URI.parse('http://169.254.169.254/latest/meta-data/instance-id')
      req = Net::HTTP::Get.new(url.to_s)
      Net::HTTP.start(url.host, url.port) { |http| http.request(req) }.body
    end

    # Check if the AMI image with the image id is created. Note that this is
    # blocking code, we would want to run this in a separate thread.
    #
    # @todo make the magic number '10' configurable via config file
    #
    # @param [String] image_id the AMI image id
    #
    # @return [Boolean] +true+ if the image is created successfully, +false+
    #                   otherwise.
    def image_created_successfully?(image_id)
      fail 'Image id is unavailable' if image_id.nil?

      # #@todo Side effects, bad design
      retry_countdown = 5
      image = @aws_ec2.images.filter('image-id', image_id)
      image_status = image.count == 0 ? nil : image.first.state

      while !(image_status == :available || image_status == :failed) && retry_countdown > 0
        puts "Image #{image.first.id} (name: #{image.first.name}) has status #{image_status}."
        sleep(10)
        image_status = @aws_ec2.images[image_id].state

        retry_countdown -= 1 if image_status.nil?
      end

      image_status == :available
    end

    # Back up the EC2 instance by creating new AMI image.
    #
    # @param instance [Instance] the EC2 instance to be backed up
    #
    # @return [String] the AMI image id.
    def backup_instance(instance)
      instance = retrieve_instances[instance.id]
      instance_name = instance.tags['Name']
      datetime_stamp = Time.now.getutc.strftime('%Y%m%d_%H%M%S')

      ami_name = "#{instance_name}_#{datetime_stamp}"
      ami_description = "#{@ami_description_prepender} - #{ami_name}"
      ami = instance.create_image(ami_name, description: ami_description, no_reboot: true)
      puts "The AMI id is #{ami.image_id}"
      ami.image_id if image_created_successfully?(ami.image_id)
    end

    # Retrieve the list of AMI images that's available to the account
    #
    # @return [ImageCollection] the collection of AMI images.
    def retrieve_images
      @aws_ec2.images
    end

    # Retrieve the list of all EBS snapshots available to the account
    #
    # @return [SnapshotCollection] the collection of EBS snapshots.
    def retrieve_snapshots
      @aws_ec2.snapshots
    end

    # Given an AMI image, get the "created at" date time.
    #
    # @param image [Image] the AMI image
    #
    # @return [DateTime] the "created at" date time.
    def get_image_datetime_stamp(image)
      image_datetimestamp_string = image.name.gsub(/([\w_]+)([\d]{8}_[\d]{6})$/, '\2')
      DateTime.strptime(image_datetimestamp_string, '%Y%m%d_%H%M%S')
    end

    # Get the tag value for an instance.
    #
    # @param instance_id [String] the id of the instance
    # @param key [String] the key of the tag we want to get
    def get_tag_value(instance_id, key)
      instance = retrieve_instances[instance_id]
      instance.tags[key]
    end

    # Get the private ip of an instance
    #
    # @param instance_id [String] the id of the instance
    #
    # @return [String] the private ip of the instance
    def get_instance_private_ip(instance_id)
      instance = retrieve_instances[instance_id]
      instance.private_ip_address
    end

    # Attach an EBS Volume to an EC2 instance.
    #
    # @param volume_id [String] The ID of the EBS volume
    # @param instance_id [String] The ID of the EC2 instance
    # @param device [String] The device name to expose to the instance
    #
    # @return [String] The attachment state of the volume
    def attach_ebs_volume(volume_id, instance_id, device)
      resp = @aws_ec2.attach_volume(volume_id: volume_id, instance_id: instance_id, device: device)
      # log "CLASS=ec2, METHOD=attach_ebs_volume, VOLUME_ID=volume_id, INSTANCE_ID=instance_id, DEVICE=device, ATTACHMENT_STATE=resp[:state], STATUS=OK"
      resp[:state]
    end

    # Check reserved instances capacity
    #
    # @param instance_types [String] Optional comma separated list of instance types to check.
    #
    # @return [Array] Structure of reservations - refer to AWS docs:
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_reserved_instances-instance_method
    def check_reserved_instances(instance_types)
      options = if instance_types.empty?
                  {
                    filters: [
                      { name: "state", values: ["active"] }
                    ]
                  }
                else
                  {
                    filters: [
                      { name: "instance-type", values: instance_types.split(',')},
                      { name: "state", values: ["active"] }
                    ]
                  }
                end

      resp = @aws_ec2.describe_reserved_instances(options)
      resp.reserved_instances
    end

    # Check running instances
    #
    # @param instance_types [String] Optional comma separated list of instance types to check.
    #
    # @param spot_instances [Boolean] either to filter spot instances or not
    #
    # @return [Array] Array structure of running instances - refer to AWS docs:
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_instances-instance_method
    def describe_instances(instance_types, spot_instances=false)
      options = if instance_types.empty?
                {
                  filters: [
                    { name: "instance-state-name", values: ["running"]}
                  ]
                }
                else
                  {
                    filters: [
                      { name: "instance-type", values: instance_types.split(',')},
                      { name: "instance-state-name", values: ["running"]}
                    ]
                  }
                end

      options[:filters].push({ name: "instance-lifecycle", values: ["spot"]}) if spot_instances
      resp = @aws_ec2.describe_instances(options)
      resp.reservations.flatten.map{ |i| i.instances}
    end

    # Get all public and private ip addresses associated to EC2 instances
    #
    # @return [Array] private and public ip addresses associated to EC2 instances
    def ec2_ips()
      instances = ec2_instances()
      interfaces = network_interfaces(instances)

      interfaces.inject([]) do |ips, interface|
        ips << interface.private_ip_address
        ips << interface.association.public_ip unless interface.association.nil?
        ips
      end
    end

    # Get network all interfaces associated to EC2 instances
    #
    # @param ec2_instances [Array] Array structure of EC2 instances
    #
    # @return [Array] Array structure of network interfaces associated to EC2
    #                 instances
    def network_interfaces(ec2_instances)
      ec2_instances.map(&:network_interfaces).flatten
    end

    # Get all EC2 instances
    #
    # @return [Array] Array structure of all instances
    def ec2_instances()
      @aws_ec2.describe_instances.reservations.map { |vm| vm.instances }.flatten
    end

    # Get AWS regions
    #
    # @return [Array] AWS regions
    def ec2_regions()
      @aws_ec2.describe_regions.regions.map { |region| region.region_name }
    end
  end
end
