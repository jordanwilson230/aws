require 'spec_helper'

describe AwsManager::Util::Validators, unit: true do
  # Unit test for: def self.diff_files(file_source_path, file_target_path)
  describe '::instance_type' do
    context 'given ``instanceType``' do
      context 'is random string' do
        it 'raise error' do
          expect{
            AwsManager::Util::Validators.instance_type('blahblahblah')
          }.to raise_error
        end
      end
      context 'is a number' do
        it 'raise error' do
          expect{
            AwsManager::Util::Validators.instance_type(12345)
          }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns true' do
          valid = AwsManager::Util::Validators.instance_type('t2.micro')
          expect(valid).to eq(true)
        end
      end
    end
  end

end
