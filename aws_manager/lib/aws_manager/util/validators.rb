module AwsManager
  module Util
    class Validators
      # Validate that an instance type string follows the AWS format at least
      #
      # @param instanceType [String] String of instance type to validate
      #
      # @return [Boolean] true if valid, raises error otherwise
      def self.instance_type(instanceType)
        if instanceType.match(/^[a-z1-9]{2,3}\.[a-z1-9]+$/).nil?
          raise InstanceTypeError, "Instance type [#{instanceType}] supplied is invalid."
        else
          true
        end
      end

      # Validate state for spot instances
      #
      # @param state [String] String of instance state to validate
      # @param instance [String] Type of instance e.g. spot, ondemand etc
      #
      # @return [Boolean] true if valid, raises error otherwise
      def self.instance_state(state, instance)
        validStates = {
          "spot" => ["open", "active", "closed", "cancelled", "failed"]
        }
        if not validStates[instance.downcase!].include? state.downcase!
          raise StateTypeError, "Supplied state [#{state}] is invalid for a [#{instance}] instance. Must be one of:\n #{validStates}"
        else
          true
        end
      end

      class InstanceTypeError < SyntaxError; end
      class StateTypeError < SyntaxError; end
    end

  end
end
