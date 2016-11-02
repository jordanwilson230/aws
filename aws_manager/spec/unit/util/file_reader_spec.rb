require 'spec_helper'

describe AwsManager::Util::FileReader, unit: true do
  describe '::read_file_path' do
    before do
      allow(File).to receive(:read).with(anything).and_raise('error')
      allow(File).to receive(:read).with('valid_file_path') { 'Success' }
    end

    context 'given ``file_path``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::FileReader.read_file_path(nil)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::FileReader.read_file_path(double('random'))
          }.to raise_error
        end
      end
      context 'is random string' do
        it 'raise error' do
          expect{
            AwsManager::Util::FileReader.read_file_path('minbhmiarjfenql9')
          }.to raise_error
        end
      end
      context 'is valid' do
        it 'receive text' do
          content = AwsManager::Util::FileReader.read_file_path('valid_file_path')
          expect(content).to eq('Success')
        end
      end
    end
  end
end
