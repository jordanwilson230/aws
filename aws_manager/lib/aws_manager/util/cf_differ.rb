require 'fileutils'
require 'aws_manager/errors'
require 'diffy'

module AwsManager
  module Util
    class CloudFormationDiffer
      # Reads text from two files provided and does a diff on them
      #
      # @param [String] file_source_path The path to the first file
      # @param [String] file_target_path The path to the second file
      #
      # @return [String] Return the diff result as String
      def self.diff_files(file_source_path, file_target_path)
        source_file = File.read(file_source_path)
        target_file = File.read(file_target_path)
        diff = Diffy::Diff.new(source_file, target_file, context: 1).to_s(:color).chomp
        diff
      rescue Exception
        raise AwsManager::CloudFormationDiffError, 'Cannot read from file(s)'
      end

      # Performs a diff on the provided templates(as String)
      #
      # @param [String] remote_template The remote template String
      # @param [String] local_template The local template String
      #
      # @return [Boolean] Return  true when diffs found, false otherwise
      def self.diff_templates(remote_template, local_template)
        templates_diffs = Diffy::Diff.new(remote_template, local_template, context: 10).to_s(:color).chomp
        if (templates_diffs == '')
          puts 'No templates diffs found.'
          return false
        else
          puts 'Found templates diffs:'
          puts '######################### Templates diffs begin  #########################'
          puts templates_diffs
          puts '######################### Templates  diffs end   #########################'
          return true
        end
        rescue Exception
          raise AwsManager::CloudFormationDiffError, 'Cannot diff the provided templates'
      end

      # Performs a diff on the provided parameters Arrays, ignoring the keys from the ignore_params Array
      #
      # @param [Array] remote_params The remote parameters Array
      # @param [Array] local_params The local parameters Array
      # @param [Array] ignore_params The parameters Array that have to be ignored from the diff
      #
      # @return [Boolean] Return  true when diffs found, false otherwise
      def self.diff_params(remote_params, local_params, ignore_params)
        # Step 1: Remove the ignored parameters
        remote_params_clear = remote_params.reject { |row| ignore_params.include?(row['parameter_key']) }
        local_params_clear = local_params.reject { |row| ignore_params.include?(row['parameter_key']) }

        # Step 2: Reduce the parmeters maps to {'parameter_key' => "#{parameter_key}", 'parameter_value' => "#{parameter_value}"}
        remote_params_reduce = remote_params_clear.map { |row| { 'parameter_key' => row['parameter_key'], 'parameter_value' => row['parameter_value'] } }
        local_params_reduce = local_params_clear.map { |row| { 'parameter_key' => row['parameter_key'], 'parameter_value' => row['parameter_value'] } }

        # Step 3: Fill the local params hash with remote params that have default values(non-required)
        fill_params_with_default_values(remote_params_reduce, local_params_reduce)

        # Step 4: Sort parameters so they can be compared as Strings on the next step
        remote_params_sort_reduce = remote_params_reduce.sort { |x, y| x['parameter_key'] <=> y['parameter_key'] }
                                    .map { |row| { row['parameter_key'] => row['parameter_value'] } }

        local_params_sort_reduce = local_params_reduce.sort { |x, y| x['parameter_key'] <=> y['parameter_key'] }
                                   .map { |row| { row['parameter_key'] => row['parameter_value'] } }

        params_diffs = Diffy::Diff.new(array_to_string(remote_params_sort_reduce), array_to_string(local_params_sort_reduce), context: 10).to_s(:color).chomp

        if (params_diffs == '')
          puts 'No parameters diffs found.'
          return false
        else
          puts 'Found parameters diffs:'
          puts '######################### Parameters diffs begin #########################'
          puts params_diffs
          puts '######################### Parameters diffs end   #########################'
          return true
        end
      rescue Exception => e
        raise AwsManager::CloudFormationDiffError, "Cannot diff the provided parameters, root cause:#{e}"
      end

      # Join the Array members into String with the provided delimiter and appends the delimiter to the end of the String generated
      # @param array_input [Array] The Array of hashes with parameters to be joined into a String
      #
      # @return [String] The generated String.
      def self.array_to_string(array_input, delimiter = "\n")
        array_input.join(delimiter) + delimiter
      end

      # Fill the local_params hash with {key, values} from remote_params hash that are missing on the local_params hash
      # The missing params are the ones not qualified as 'required', which have defaults values
      # @param remote_params [Array] The Array of hashes with remote parameters
      # @param local_params [Array] The Array of hashes with local parameters
      #
      def self.fill_params_with_default_values(remote_params, local_params)
        remote_params.each do |hsh_remote|
          fill = true
          local_params.each do |hsh_local|
            fill = false if hsh_local['parameter_key'] == hsh_remote['parameter_key']
          end
          local_params.push(hsh_remote) if fill
        end
      end
    end
  end
end
