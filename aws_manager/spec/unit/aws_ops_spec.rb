require 'spec_helper'

describe AwsManager::AwsOps, unit: true do
  let(:aws_ops) {
    cf = double('cloudformation')
    ec2 = double('ec2')
    stack = double('stack')
    autoscaling = double('autoscaling')
    allow(stack).to receive(:name) { 'stack name' }

    allow(ec2).to receive(:retrieve_instance_id) { 'instance_id' }
    allow(ec2).to receive(:get_tag_value).and_raise('Error')
    allow(ec2).to receive(:get_tag_value)\
      .with('instance_id', 'aws:cloudformation:stack-name') { 'stack_name' }
    allow(ec2).to receive(:get_tag_value)\
      .with(any_args, 'aws:autoscaling:groupName') { 'asg_name' }
    allow(ec2).to receive(:retrieve_instances) {
      instances = double('instances')
      instance = double('instance')
      allow(instance).to receive(:map) { [stack] }
      allow(instance).to receive(:image_id) { 'image id' }
      allow(instance).to receive(:name) { 'name' }
      allow(instance).to receive(:deregister)
      allow(instance).to receive(:exists?) { false }
      allow(instance).to receive(:block_devices) {
        block_device = double('block_device')
        allow(block_device).to receive(:[]).with(:ebs) {
          ebs = double('ebs')
          allow(ebs).to receive(:[]).with(:snapshot_id) { 'snapshot_id' }
          ebs
        }
        [block_device]
      }
      allow(instances).to receive(:filter) { instance }
      allow(instances).to receive(:[]) { instance }
      instances
    }
    allow(ec2).to receive(:retrieve_snapshots) {
      snapshots = double('snapshots')
      allow(snapshots).to receive(:[]) {
        snapshot = double('snapshot')
        allow(snapshot).to receive(:delete) {}
        allow(snapshot).to receive(:exists?) { false }
        snapshot
      }
      snapshots
    }
    allow(ec2).to receive(:get_image_datetime_stamp).and_raise('Error')
    allow(ec2).to receive(:get_image_datetime_stamp).with(image) { DateTime.now }
    allow(ec2).to receive(:retrieve_images) {
      images = double('images')
      allow(images).to receive(:with_owner) { images }
      allow(images).to receive(:filter) { images }
      allow(images).to receive(:filter).with('state', 'available') { [image] }
      allow(images).to receive(:[]) { image }
      images
    }
    allow(ec2).to receive(:backup_instance) { 'ami_id' }

    allow(cf).to receive(:get_stack) { stack }
    allow(cf).to receive(:backup_stack) { true }
    allow(cf).to receive(:update_stack_ami_id) { true }

    allow(autoscaling).to receive(:get_group_resources) {
      group = double('group')
      allow(group).to receive(:physical_resource_id) { 'asg_name' }
      [group]
    }
    allow(autoscaling).to receive(:retrieve_instance_ids) { ['instance_id'] }

    AwsManager::AwsOps.new(cf, ec2, autoscaling)
  }
  let(:broken_aws_ops) {
    cf = double('broken-cloudformation')
    ec2 = double('broken-ec2')

    allow(ec2).to receive(:retrieve_instances).and_raise('Borken EC2 Error')
    allow(ec2).to receive(:retrieve_images).and_raise('Broken EC2 Error')
    allow(ec2).to receive(:delete_ami?).and_raise('Broken EC2 Error')
    allow(cf).to receive(:backup_stack).and_raise('CloudFormation error')

    AwsOps.new(cf, ec2)
  }
  let(:image) {
    image = double('image')
    allow(image).to receive(:block_devices) {
      block_device = { ebs: { snapshot_id: 'snapshot_id' } }
      Array.new(1, block_device)
    }
    allow(image).to receive(:image_id) { 'image id' }
    allow(image).to receive(:name) { 'name' }
    allow(image).to receive(:deregister) { 'deregister'  }
    allow(image).to receive(:exists?) { false }
    image
  }
  let(:borken_image) {
    image = double('broken_image')
    allow(image).to receive(:block_devices).and_raise('Broken Image Error')
    allow(image).to receive(:image_id).and_raise('Broken Image Error')
    allow(image).to receive(:name).and_raise('Broken Image Error')
    image
  }

  describe '#get_stacks_of_instance' do
    context 'given `instance_id`' do
      context 'is nil' do
        it 'raise error' do
          expect { broken_aws_ops.get_stack_of_instance(nil) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns stack' do
          s = aws_ops.get_stack_of_instance('instance_id')
          expect(s.name).to eq('stack name')
        end
      end
    end
  end

  describe '#delete_backup_amis' do
    context 'broken ec2' do
      it 'raise error' do
        expect { broken_aws_ops.delete_backup_amis }.to raise_error
      end
    end
    context 'valid ec2' do
      it 'returns true' do
        expect(aws_ops.delete_backup_amis).to be true
      end
    end
  end

  describe '#delete_ami' do
    context 'broken image' do
      it 'raise error' do
        expect { aws_ops.delete_ami(broken_image) }.to raise_error
      end
    end
    context 'valid image' do
      it 'returns true' do
        expect(aws_ops.delete_ami(image)).to be true
      end
    end
  end

  describe '#delete_ami?' do
    context 'given `image`' do
      context 'is nil' do
        it 'raise error' do
          expect { aws_ops.delete_ami?(nil) }.to raise_error
        end
      end
      context 'is valid to be kept' do
        it 'returns false' do
          expect(aws_ops.delete_ami?(image)).to be false
        end
      end
    end
  end

  describe '#backup_instance' do
    context 'invalid instance' do
      it 'raise error' do
        expect { broken_aws_ops.backup_instance }.to raise_error
      end
    end
    context 'valid instance' do
      it 'returns ami id' do
        expect(aws_ops.backup_instance).to eq('ami_id')
      end
    end
  end

  describe '#backup?' do
    context 'given `instance_id`' do
      context 'is nil' do
        it 'raise error' do
          expect { aws_ops.backup?(nil) }.to raise_error
        end
      end
    end
  end
end
