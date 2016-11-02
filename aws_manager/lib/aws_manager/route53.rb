require 'aws-sdk'
require 'socket'
require 'system/getifaddrs'

module AwsManager
  class Route53
    def initialize(route53 = nil)
      @route53 = route53 || Aws::Route53::Client.new
    end

    # Modify a Route53 record set using the parameters provided
    #
    # @param action [String] the change action to perform CREATE | DELETE | UPSERT
    # @param hosted_zone_id [String] the existing hosted zone id to be used for creating
    #                                the record set
    # @param domain_name [String] the existing domain name to be used for creating the
    #                             record set
    # @param record_name [String] the name to be used for creating the record set
    # @param interface [String] the type of network interface to be used for creating the
    #                           record set
    # @param ttl [Int] the TTL to use for the record.
    #
    # @return [String] the ID of the change request
    def change_record_set(action, hosted_zone_id, domain_name, record_name, interface, ttl = 300)
      ifaddress = System.get_ifaddrs
      ip = "#{ifaddress[interface.to_sym][:inet_addr]}"

      resp = @route53.change_resource_record_sets(
        hosted_zone_id: "#{hosted_zone_id}",
        change_batch: {
          comment: "Creating a record set for: #{ip}",
          changes: [
            {
              action: "#{action}",
              resource_record_set: {
                name: "#{record_name}.#{domain_name}",
                type: 'A',
                ttl: ttl,
                resource_records: [
                  {
                    value: "#{ip}"
                  }
                ]
              }
            }
          ]
        }
      )
      # log "CLASS=route53, METHOD=change_record_set, ACTION=action, HOSTED_ZONE_ID=hosted_zone_id,
      # DOMAIN_NAME=domain_name, RECORD_NAME=record_name, INTERFACE=interface, TTL=ttl,
      # CHANGE_ID=resp[:change_info][:id], STATUS=OK"
      resp[:change_info][:id]
    end

    # Get hosted zone id by hosted zone name
    #
    # @param zone_name [String] hosted zone name
    #
    # @return [String] hosted zone id
    def get_zone_id_by_name(zone_name)
      @route53.list_hosted_zones.hosted_zones.
        select { |zone| zone.name == zone_name+"." }.
        first.id.split('/').
        last
    end

    # Get 'A' record sets for a specific hosted zone
    #
    # @param hosted_zone_id [String] hosted zone id
    #
    # @return [Array] Route53 record sets structs
    def get_a_recordsets(hosted_zone_id)
      @route53.list_resource_record_sets(hosted_zone_id: hosted_zone_id).
        resource_record_sets.
        select { |record| record.type == 'A' && !record.resource_records.nil? }
    end

    # Delete Route53 record set
    #
    # @param hosted_zone_id [String] hosted zone id
    #
    # @param record_set [Hash] record set struct
    #
    # @return [String] the ID of the delete request
    def delete_recordset(hosted_zone_id, record_set)
      @route53.change_resource_record_sets(
        hosted_zone_id: hosted_zone_id,
        change_batch: {
          changes: [
            {
              action: "DELETE",
              resource_record_set: record_set
            }
          ]
        }
      ).change_info.to_h
    end
  end
end
