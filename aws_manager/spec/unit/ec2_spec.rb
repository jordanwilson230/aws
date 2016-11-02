require 'spec_helper'

describe AwsManager::Ec2, unit: true do
  let(:ec2) {
    aws_ec2 = double('aws_ec2')
    instances = [instance]
    allow(aws_ec2).to receive(:instances) { instances }
    allow(instances).to receive(:[]).and_raise('Error')
    allow(instances).to receive(:[]).with('instance_id') { instance }

    image = double('image')
    allow(image).to receive(:state) { :available }
    images = double('images')
    allow(images).to receive(:filter) { images }
    allow(images).to receive(:count) { 1 }
    allow(images).to receive(:[]).with(anything).and_raise('Invalid Image Id')
    allow(images).to receive(:[]) { image }
    allow(images).to receive(:success?) { true }
    allow(images).to receive(:first) { image }

    snapshot = double('snapshot')
    volume_attachment_response = double('volume_attachment_response')
    allow(volume_attachment_response).to receive(:[])
      .with(:state) { volume_attachment_state }

    allow(aws_ec2).to receive(:images) { images }
    allow(aws_ec2).to receive(:snapshots) { [snapshot] }
    allow(aws_ec2).to receive(:attach_volume)
      .with(
        volume_id: volume_id,
        instance_id: instance_id,
        device: device
      ) { volume_attachment_response }

    allow(Net::HTTP).to receive(:start) {
      body = double('body')
      allow(body).to receive(:body) { 'instance_id' }
      body
    }

    AwsManager::Ec2.new(aws_ec2)
  }
  let(:invalid_ec2) {
    image = double('image')
    allow(image).to receive(:state) { :failed }
    images = double('images')
    allow(images).to receive(:[]) { image }
    allow(images).to receive(:count) { 1 }
    allow(images).to receive(:filter) { images }
    allow(images).to receive(:first) { image }

    invalid_aws_ec2 = double('invalid aws ec2')
    allow(invalid_aws_ec2).to receive(:images) { images }
    allow(invalid_aws_ec2).to receive(:instances).and_raise('Invalid EC2 Error')
    allow(Net::HTTP).to receive(:start).and_raise('Http Error')
    AwsManager::Ec2.new(invalid_aws_ec2)
  }
  let(:broken_ec2) {
    broken_aws_ec2 = double('broken aws ec2')
    allow(broken_aws_ec2).to receive(:images).and_raise('Broken EC2 Error')
    allow(broken_aws_ec2).to receive(:snapthosts).and_raise('Borken EC2 Error')
    AwsManager::Ec2.new(broken_aws_ec2)
  }
  let(:instance) {
    i = double('instance')
    allow(i).to receive(:tags) {
      tags = double('tags')
      allow(tags).to receive(:[]) { 'instance_name' }
      tags
    }
    allow(i).to receive(:create_image) {
      ami = double('ami')
      allow(ami).to receive(:image_id) { 'ami_id' }
      ami
    }
    allow(i).to receive(:tags) {
      tags = double('tags')
      allow(tags).to receive(:[]) { 'value' }
      tags
    }
    allow(i).to receive(:id) { 'instance_id' }
    i
  }
  let(:image) {
    img = double('img')
    allow(img).to receive(:name) { 'abc_20141117_160304' }
    img
  }
  let(:invalid_image) {
    invalid_img = double('invalid_img')
    allow(invalid_img).to receive(:name) { 'abc' }
    invalid_img
  }
  let(:date_time) {
    DateTime.strptime('20141117_160304', '%Y%m%d_%H%M%S')
  }
  let(:volume_id) { 'vol-12345678' }
  let(:invalid_volume_id) { 'invalid-volume-12345' }
  let(:instance_id) { 'i-12345678' }
  let(:device) { 'xvdf' }
  let(:volume_attachment_state) { 'pending' }

  describe '#get_instance' do
    context 'invalid ec2' do
      it 'raise error' do
        expect { invalid_ec2.retrieve_instances }.to raise_error
      end
    end
    context 'valid ec2' do
      it 'returns instances' do
        expect(ec2.retrieve_instances.size).to eq(1)
      end
    end
  end

  describe '#retrieve_instance_id' do
    context 'bad http' do
      it 'raise error' do
        expect { invalid_ec2.retrieve_instance_id }.to raise_error
      end
    end
    context 'valid http' do
      it 'returns instance id' do
        expect(ec2.retrieve_instance_id).to eq('instance_id')
      end
    end
  end

  describe '#image_created_successfully?' do
    context 'given `image_id`' do
      context 'is nil' do
        it 'raise error' do
          expect { ec2.image_created_successfully?(nil) }.to raise_error
        end
      end
      context 'is invalid' do
        it 'returns false' do
          r = invalid_ec2.image_created_successfully?('image_id')
          expect(r).to be false
        end
      end
      context 'is valid' do
        it 'returns true' do
          r = ec2.image_created_successfully?('image_id')
          expect(r).to be true
        end
      end
    end
  end

  describe '#backup_instance' do
    context 'given `instnace`' do
      context 'is nil' do
        it 'raise error' do
          expect { ec2.backup_instance(nil) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns AMI id' do
          ami_id = ec2.backup_instance(instance)
          expect(ami_id).to eq('ami_id')
        end
      end
    end
  end

  describe '#retrieve_images' do
    context 'invalid ec2' do
      it 'raise error' do
        expect { broken_ec2.retrieve_images }.to raise_error
      end
    end
    context 'valid ec2' do
      it 'returns images' do
        images = ec2.retrieve_images
        expect(images.success?).to be true
      end
    end
  end

  describe '#retrieve_snapshots' do
    context 'invalid ec2' do
      it 'raise error' do
        expect { broken_ec2.retrieve_snapshots }.to raise_error
      end
    end
    context 'valid ec2' do
      it 'returns snapshots' do
        snapshots = ec2.retrieve_snapshots
        expect(snapshots.size).to eq(1)
      end
    end
  end

  describe '#get_image_datetime_stamp' do
    context 'given `image`' do
      context 'is nil' do
        it 'raise error' do
          expect { ec2.get_image_datetime_stamp(nil) }.to raise_error
        end
      end
      context 'is invalid' do
        it 'raise error' do
          expect { ec2.get_image_datetime_stamp(invalid_image) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns date time stamp' do
          timestamp = ec2.get_image_datetime_stamp(image)
          expect(timestamp).to eq(date_time)
        end
      end
    end
  end

  describe '#get_tag_value' do
    context 'given `instance_id`' do
      context 'is nil' do
        it 'raise error' do
          expect { ec2.get_tag_value(nil, 'key') }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `key`' do
          context 'is valid' do
            it 'returns value' do
              value = ec2.get_tag_value('instance_id', 'key')
              expect(value).to eq('value')
            end
          end
        end
      end
    end
  end

  describe '#attach_ebs_volume' do
    context 'given `volume_id`' do
      context 'is invalid' do
        it 'raise error' do
          expect { ec2.attach_ebs_volume(invalid_volume_id, instance_id, device) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns attachment state' do
          expect(ec2.attach_ebs_volume(volume_id, instance_id, device)).to eq(volume_attachment_state)
        end
      end
    end
  end
end
