require 'spec_helper'

describe AwsManager::AutoScaling, unit: true do
  def construct_stack(contains_asg)
    stack = double('stack')
    resources = double('resources')
    resource = double('resource')
    allow(resource).to receive(:resource_type) {
      contains_asg ? 'AWS::AutoScaling::AutoScalingGroup' : 'Not ASG'
    }
    allow(resources).to receive(:enum) { [resource] }
    allow(stack).to receive(:resources) { resources }
    stack
  end

  let(:auto_scaling) {
    as = double('aws_auto_scaling')
    groups = double('groups')
    asg_group = double('group')
    allow(groups).to receive(:[]).with('invalid_name') { nil }
    allow(groups).to receive(:[]).with('valid_name') { asg_group }
    allow(asg_group).to receive(:success?) { true }
    instance = double('instance')
    allow(instance).to receive(:instance_id) { 'instance_id' }
    allow(asg_group).to receive(:auto_scaling_instances) { [instance] }
    allow(as).to receive(:groups) { groups }
    AwsManager::AutoScaling.new(as)
  }
  let(:stack_with_asg) { construct_stack(true) }
  let(:stack_without_asg) { construct_stack(false) }

  describe '#get_group_resource' do
    context 'given `stack`' do
      context 'is nil' do
        it 'raise error' do
          expect{
            auto_scaling.get_group_resources(nil)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'has ASG' do
          it 'returns ASG stack' do
            asg_resources = auto_scaling.get_group_resources(stack_with_asg)
            resource_type = asg_resources[0].resource_type
            expect(resource_type).to eq('AWS::AutoScaling::AutoScalingGroup')
          end
        end
        context 'has_not ASG' do
          it 'returns empty array' do
            asg_resources = auto_scaling.get_group_resources(stack_without_asg)
            expect(asg_resources).to match_array([])
          end
        end
      end
    end
  end

  describe('#get_group') do
    context 'given `group_name`' do
      context 'is nil' do
        it 'raise error' do
          expect{
            auto_scaling.get_group(nil)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'does exist' do
          it 'returns asg' do
            asg = auto_scaling.get_group('valid_name')
            expect(asg.success?).to be true
          end
        end
        context 'does not exist' do
          it 'returns nil' do
            asg = auto_scaling.get_group('invalid_name')
            expect(asg).to be_nil
          end
        end
      end
    end
  end

  describe '#retrieve_instance_ids' do
    context 'given `group_name`' do
      context 'is nil' do
        it 'raise error' do
          expect { auto_scaling.retrieve_instance_ids(nil) }.to raise_error
        end
      end
      context 'is valid group' do
        it 'returns list of instance ids' do
          instance_ids = auto_scaling.retrieve_instance_ids('valid_name')
          expect(instance_ids.first).to eq('instance_id')
          expect(instance_ids.size).to eq(1)
        end
      end
    end
  end

  describe '#group_resource_type?' do
    context 'given `resource_type`' do
      context 'is ASG' do
        it 'returns ture' do
          result =
            auto_scaling.send(:group_resource_type?,
                              'AWS::AutoScaling::AutoScalingGroup')
          expect(result).to be true
        end
      end
      context 'is not ASG' do
        it 'returns ture' do
          result =
            auto_scaling.send(:group_resource_type?,
                              'NotAutoScalingGroup')
          expect(result).to be false
        end
      end
    end
  end
end
