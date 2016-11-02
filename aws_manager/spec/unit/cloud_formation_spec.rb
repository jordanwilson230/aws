require 'spec_helper'

describe AwsManager::CloudFormation, unit: true do
  let(:cf) {
    allow(JSON).to receive(:parse).with('good_template') { template }
    allow(JSON).to receive(:parse).with('bad_template') { bad_template }
    allow(AwsManager::Util::FileReader).to receive(:read_file_path)
      .with(anything).and_raise('FileReader Error')
    allow(AwsManager::Util::FileReader).to receive(:read_file_path)
      .with(template_path) { template }
    allow(AwsManager::Util::FileReader).to receive(:read_file_path)
      .with(bad_template_path) { bad_template }

    allow(AwsManager::Util::YamlLoader).to receive(:load_yaml_file_path)
      .with(anything).and_raise('YamlLoader Error')
    allow(AwsManager::Util::YamlLoader).to receive(:load_yaml_file_path)
      .with(params_path) { params }

    allow(AwsManager::CloudFormationOps).to receive(:generate_stack_name)
      .with(params, template_path) { stack_name }
    allow(AwsManager::CloudFormationOps).to receive(:get_required_parameters) { [] }

    stack_id = double('stack_id')
    stack = double('stack')
    allow(stack).to receive(:[]) { stack_id }
    allow(stack).to receive(:success?) { true }
    allow(stack).to receive(:delete) { nil }
    allow(stack).to receive(:parameters) { [] }
    allow(stack).to receive(:outputs) { [] }
    cf_template = double('template')
    allow(cf_template).to receive(:template_body) { template }

    aws_cf = double('aws_cf')
    allow(aws_cf).to receive(:create_stack)
      .with(hash_including(stack_name: stack_name)) { stack }
    allow(aws_cf).to receive(:get_template)
      .with(hash_including(stack_name: stack_name)) { cf_template }
    allow(aws_cf).to receive(:update_stack)
      .with(hash_including(stack_name: stack_name)) { stack }
    allow(aws_cf).to receive(:stacks) {
      stacks = double('stacks')
      allow(stacks).to receive(:create)
        .with(stack_name, anything, anything) { stack }
      allow(stacks).to receive(:[]).and_raise('GetStack Error')
      allow(stacks).to receive(:[])
        .with(stack_name) { stack }
      allow(stacks).to receive(:[])
        .with(invalid_stack_name) { nil }
      stacks
    }
    allow(aws_cf).to receive(:validate_template)
      .with(template_body: template) { true }
    allow(aws_cf).to receive(:validate_template)
      .with(template_body: bad_template) { false }
    allow(aws_cf).to receive(:validate_template)
      .with(template_body: invalid_template) { false }
    allow(aws_cf).to receive(:describe_stacks)
      .with(stack_name: 'stack_name') {
        stacks = double('stacks')
        stack_desc = double('stack_desc')
        allow(stack_desc).to receive(:stack_status)
        allow(stacks).to receive(:[]) { [stack_name] }
        allow(stacks).to receive(:[]) { [stack_desc] }
        allow(stacks).to receive(:stacks) { [stack] }
        stacks
      }

    aws_cf_resource = double('aws_cf_resource')
    allow(aws_cf_resource).to receive(:stack)
      .with(stack_name) { stack }
    allow(aws_cf_resource).to receive(:stack)
      .with(invalid_stack_name) { nil }

    autoscaling = double('autoscaling')
    resource = double('resource')
    allow(resource).to receive(:physical_resource_id) { 'resource_id' }
    allow(autoscaling).to receive(:get_group_resources) { [resource] }
    group = double('group')
    instance = double('instance')
    allow(instance).to receive(:instance_id) { 'instance id' }
    allow(group).to receive(:auto_scaling_instances) { [instance] }
    allow(autoscaling).to receive(:get_group) { group }

    ec2 = double('ec2')
    ec2_instances = double('ec2_instances')
    allow(ec2_instances).to receive(:[]) { double('ins') }
    allow(ec2).to receive(:retrieve_instances) { ec2_instances }
    allow(ec2).to receive(:backup_instance) { 'ami_id' }

    AwsManager::CloudFormation.new(aws_cf, aws_cf_resource, autoscaling, ec2)
  }
  let(:params_path) { 'params_path' }
  let(:params) { 'params' }
  let(:stack_name) { 'stack_name' }
  let(:template_path) { 'template_path' }
  let(:bad_template_path) { 'bad_template_path' }
  let(:template) { 'good_template' }
  let(:bad_template) { 'bad_template' }
  let(:invalid_template) { 'invalid_template' }
  let(:invalid_template_path) { 'invalid_template_path' }
  let(:stack_name) { 'stack_name' }
  let(:invalid_stack_name) { 'invalid_stack_name' }
  let(:stack) {
    s = double('s')
    allow(s).to receive(:status) { 'UPDATE_COMPLETE' }
    allow(s).to receive(:template) { 'template' }
    allow(s).to receive(:parameters) { { 'BaseAmiId' => 'base_ami_id' } }
    allow(s).to receive(:update) { true }
    allow(s).to receive(:name) { 'stack' }
    allow(s).to receive(:stack_name) { 'stack' }
    s
  }
  let(:failed_stack) {
    s = double('s')
    allow(s).to receive(:status) { 'UPDATE_FAILED' }
    allow(s).to receive(:name) { 'failed stack' }
    s
  }

  describe '#create_stack' do
    context 'given `template_path`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.create_stack(nil, params_path) }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `parameters_path`' do
          context 'is nil' do
            it 'raise error' do
              expect { cf.create_stack(template_path, nil) }.to raise_error
            end
          end
          context 'is valid' do
            it 'returns stack_id' do
              cf.create_stack(template_path, params_path)
            end
          end
        end
      end
    end
  end

  describe '#update_stack' do
    context 'given `stack_name`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.update_stack(nil, template_path, params_path) }.to raise_error
        end
      end
      context 'given `template_path`' do
        context 'is nil' do
          it 'raise error' do
            expect { cf.update_stack(stack_name, nil, params_path) }.to raise_error
          end
        end
        context 'is valid' do
          context 'given `parameters_path`' do
            context 'is nil' do
              it 'raise error' do
                expect { cf.update_stack(stack_name, template_path, nil) }.to raise_error
              end
            end
            context 'is valid' do
              it 'returns stack' do
                cf.update_stack(stack_name, template_path, params_path)
              end
            end
          end
        end
      end
    end
  end

  describe '#delete_stack' do
    context 'given `template_path`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.delete_stack(nil, params_path) }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `parameters_path`' do
          context 'is nil' do
            it 'raise error' do
              expect { cf.delete_stack(template_path, nil) }.to raise_error
            end
          end
          context 'is valid' do
            it 'returns string' do
              result = cf.delete_stack(template_path, params_path)
              expect(result).to be stack_name
            end
          end
        end
      end
    end
  end

  describe '#validate_template_file' do
    context 'given `template_path`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.validate_template_file(nil) }.to raise_error
        end
      end
      context 'is invalid' do
        it 'raise error' do
          expect { cf.validate_template_file(invalid_template_path) }.to raise_error
        end
      end
      context 'is bad template' do
        it 'returns false' do
          expect(cf.validate_template_file(bad_template_path)).to be false
        end
      end
      context 'is good template' do
        it 'returns true' do
          expect(cf.validate_template_file(template_path)).to be true
        end
      end
    end
  end

  describe '#validate_template' do
    context 'given `template`' do
      context 'is nil' do
        it 'returns false' do
          expect(cf.validate_template(nil)).to be false
        end
      end
      context 'is invalid' do
        it 'returns false' do
          expect(cf.validate_template(invalid_template)).to be false
        end
      end
      context 'is bad template' do
        it 'returns false' do
          expect(cf.validate_template(bad_template)).to be false
        end
      end
      context 'is good template' do
        it 'returns true' do
          expect(cf.validate_template(template)).to be true
        end
      end
    end
  end

  describe '#get_stack' do
    context 'given `name`' do
      context 'is nil' do
        it 'returns nil' do
          expect { cf.get_stack(nil) }.to raise_error
        end
      end
      context 'is invalid' do
        it 'returns nil' do
          expect(cf.get_stack(invalid_stack_name)).to be_nil
        end
      end
      context 'is valid' do
        it 'returns stack' do
          expect(cf.get_stack(stack_name).success?).to be true
        end
      end
    end
  end

  describe '#backup_stack' do
    context 'given `stack`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.backup_stack(nil) }.to raise_error
        end
      end
      context 'is valid stack' do
        it 'returns true' do
          r = cf.backup_stack(stack)
          expect(r).to be true
        end
      end
    end
  end

  describe '#update_stack_ami_id' do
    context 'given `stack`' do
      context 'is nil' do
        it 'raise error' do
          expect { cf.update_stack_ami_id(nil, 'ami_id') }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `ami_id`' do
          context 'is valid' do
            it 'returns true' do
              # Unit testing AWS Ruby SDK API logic removed.
            end
          end
        end
      end
    end
  end

  describe '#describe_stack_outputs' do
    context 'given `stack_name`' do
      context 'name is nil' do
        it 'raise error' do
          expect { cf.describe_stack_outputs(nil) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns outputs' do
          response = cf.describe_stack_outputs('stack_name')
          expect(response).to eq('[]')
        end
      end
    end
  end
end
