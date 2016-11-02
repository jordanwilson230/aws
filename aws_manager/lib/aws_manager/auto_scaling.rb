require 'aws-sdk'

module AwsManager
  class AutoScaling
    def initialize(aws_autoscaling = nil)
      @aws_auto_scaling = aws_autoscaling || Aws::AutoScaling::Client.new
    end

    # This will retrieve the Auto Scaling group resources from the given stack.
    #
    # @param [CloudFormation::Stack] stack The cloud formation stack
    #
    # @return [StackResourceCollection] Returns the collection of Auto Scaling
    #                                   group stack collection.
    def get_group_resources(stack)
      stack.resources.enum.select { |resource| group_resource_type?(resource.resource_type) }
    end

    # Get Auto Scaling group by name.
    #
    # @param [String] asg_name The Auto Scaling group name
    #
    # @return [AutoScaling::Group] Returns the Auto Scaling group with the given
    #                              name.
    def get_group(group_name)
      @aws_auto_scaling.groups[group_name]
    end

    # Get the list of instance id that's available to the group.
    #
    # @param group_name [String] the name of the group
    #
    # @return [[String]] the list of instance ids
    def retrieve_instance_ids(group_name)
      get_group(group_name).auto_scaling_instances.map(&:instance_id)
    end

    private

    # Check if it's an ASG resource type.
    #
    # @param [String] resource_type The type of the resource
    #
    # @returns Returns +true+ if it's an ASG resource type, +false+ otherwise
    def group_resource_type?(resource_type)
      resource_type == 'AWS::AutoScaling::AutoScalingGroup'
    end
  end
end
