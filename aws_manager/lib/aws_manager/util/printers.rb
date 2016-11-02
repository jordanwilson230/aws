require 'table_print'
require 'colorize'

module AwsManager
  module Util
    # Convenience class to pretty print intformation
    class Printers

      # Pretty print the output for check_reserved
      #
      # @param availabilityZone: the AZ within the region you've called
      # @param instanceType: instance you're calculating
      # @param instanceCount: number of all running instances found of instanceType
      # @param reservedCount: number of instances you've reserved of instanceType
      # @param spotCout: number of running spot instances found of instanceType
      # @return Null, Unit, Nada.
      def self.output_reserved_format(availabilityZone, instanceType, instanceCount, reservedCount, spotCount)
        ## The equation => #ReservedInstances - #AllRunningInstances + #AllRunningSpotInstances
        calc =  reservedCount - instanceCount + spotCount
        remainSymbol = ('+' if calc > 0) || (' ' if calc == 0) || ('' if calc < 0)
        output = "%10s | %12s | i%3d | r%3d | (%s%d)\n" % [availabilityZone, instanceType, instanceCount, reservedCount, remainSymbol, calc]
        if calc > 0
          print output.green
        elsif calc == 0
          print output.yellow
        else
          print output.red
        end
      end

      class InstanceTypeError < SyntaxError; end
    end

  end
end
