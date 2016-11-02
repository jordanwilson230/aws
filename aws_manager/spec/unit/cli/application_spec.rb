require 'spec_helper'

describe AwsManager::Cli::Application, unit: true do
  describe '#cf_create_stack' do
    context 'when required parameters are not provided' do
      let(:cf_create_stack) { AwsManager::Cli::Application.start(['cf_create_stack']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_create_stack }
        expect(result).to match("No value provided for required options '--yaml-inventory', '--cfn-template'")
      end
    end

    context 'when `--cfn-template` is used without any value' do
      let(:cf_create_stack) { AwsManager::Cli::Application.start(['cf_create_stack', '--cfn-template']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_create_stack }
        expect(result).to match("No value provided for option '--cfn-template'")
      end
    end

    context 'when `--yaml-inventory` is used without any value' do
      let(:cf_create_stack) { AwsManager::Cli::Application.start(['cf_create_stack', '--yaml-inventory']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_create_stack }
        expect(result).to match("No value provided for option '--yaml-inventory'")
      end
    end

    context 'when required parameters are set with invalid values' do
      let(:cf_create_stack) {
        AwsManager::Cli::Application.start([
          'cf_create_stack',
          '--yaml-inventory',
          'asdfasdfasdf',
          '--cfn-template',
          'asdfasdfasdf'
        ]) }

      it 'should display appropriate message' do
        result = capture(:stdout) { cf_create_stack }
        expect(result).to include('Cannot read from file')
      end
    end

    context 'when required parameters are set with valid values' do
      let(:template) { 'good_template' }
      let(:stack) {
        stack = double('stack')
        allow(stack).to receive(:name) { 'test-stack' }
        allow(stack).to receive(:stack_id) { 'test-stack-id' }
        stack
      }
      let(:cf_create_stack) {
        AwsManager::Cli::Application.start([
          'cf_create_stack',
          '--yaml-inventory',
          'valid-yaml-file',
          '--cfn-template',
          'valid-cfn-file'
        ]) }
      # it 'should create CloudFormation stack' do
        # allow(JSON).to receive(:parse).with('good_template') { template }
        # allow(AwsManager::Util::FileReader).to receive(:read_file_path).with('valid-cfn-file') { template }
        # allow(AwsManager::Util::FileReader).to receive(:read_file_path).with('valid-yaml-file') { template }
        # allow(AwsManager::CloudFormation).to receive(:create_stack).with(anything).and_return(stack)
        # result = capture(:stdout) { cf_create_stack }
        # expect(result).to include('CloudFormation Stack created successfully with id: test-stack-id')
      # end
    end
  end

  describe '#cf_update_stack' do
    context 'when required parameters are not provided' do
      let(:cf_update_stack) { AwsManager::Cli::Application.start(['cf_update_stack']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_update_stack }
        expect(result).to match("No value provided for required options '--stack-name', '--cfn-template', '--yaml-inventory'")
      end
    end

    context 'when `--stack-name` is used without any value' do
      let(:cf_update_stack) { AwsManager::Cli::Application.start(['cf_update_stack', '--stack-name']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_update_stack }
        expect(result).to match("No value provided for option '--stack-name'")
      end
    end

    context 'when `--cfn-template` is used without any value' do
      let(:cf_update_stack) { AwsManager::Cli::Application.start(['cf_update_stack', '--cfn-template']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_update_stack }
        expect(result).to match("No value provided for option '--cfn-template'")
      end
    end

    context 'when `--yaml-inventory` is used without any value' do
      let(:cf_update_stack) { AwsManager::Cli::Application.start(['cf_update_stack', '--yaml-inventory']) }

      it 'should display an appropriate error message' do
        result = capture(:stderr) { cf_update_stack }
        expect(result).to match("No value provided for option '--yaml-inventory'")
      end
    end

    context 'when required parameters are set with invalid values' do
      let(:cf_update_stack) {
        AwsManager::Cli::Application.start([
          'cf_update_stack',
          '--stack-name',
          'asdadsadsadsa',
          '--yaml-inventory',
          'asdfasdfasdf',
          '--cfn-template',
          'asdfasdfasdf'
        ]) }

      it 'should display appropriate message' do
        result = capture(:stdout) { cf_update_stack }
        expect(result).to include('Cannot read from file')
      end
    end

    context 'when required parameters are set with valid values' do
      let(:stack_name) { 'good_stack_name' }
      let(:template) { 'good_template' }
      let(:stack) {
        stack = double('stack')
        allow(stack).to receive(:name) { 'test-stack' }
        allow(stack).to receive(:stack_id) { 'test-stack-id' }
        stack
      }
      let(:cf_update_stack) {
        AwsManager::Cli::Application.start([
          'cf_update_stack',
          '--stack-name',
          '--yaml-inventory',
          'valid-yaml-file',
          '--cfn-template',
          'valid-cfn-file'
        ]) }
    end
  end

  describe '#route53_create_record' do
    context 'when required parameters are set with invalid values' do
      let(:route53) {
        route53 = double('awsmanager_route53')
        allow(route53).to receive(:change_record_set).with(anything).and_return('record_id')
      }
      let(:route53_create_record) {
        AwsManager::Cli::Application.start([
          'route53_create_record',
          '--hosted_zone_id',
          'some_zone_id',
          '--domain_name',
          'some.domain.name',
          '--record_name',
          'some_record_name',
          '--interface',
          'some_interface'
        ])}
      it 'should create Route53 record' do
        # allow(AwsManager::Route53).to receive(:change_record_set).with(anything).and_return('record_id')
        # result = capture(:stdout) { route53_create_record }
        # expect(result).to include('Successfully completed UPSERT of Route53 record')
      end
    end
  end
end
