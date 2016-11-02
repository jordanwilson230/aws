require 'spec_helper'

describe AwsManager::Util::YamlLoader, unit: true  do
  before do
    allow(YAML).to receive(:load).with(anything).and_raise('error')
    allow(YAML).to receive(:load).with('valid_yaml') { { 'ping' => 'pong' }  }
    allow(AwsManager::Util::FileReader).to receive(:read_file_path).with(anything).and_raise('error')
    allow(AwsManager::Util::FileReader).to receive(:read_file_path).with('valid_file_path') { 'valid_yaml' }
  end

  describe '::load_yaml' do
    context 'given ``yaml``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::YamlLoader.load_yaml(nil)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::YamlLoader.load_yaml(double('random'))
          }.to raise_error
        end
      end
      context 'is valid' do
        it 'get hash' do
          hash = AwsManager::Util::YamlLoader.load_yaml('valid_yaml')
          expect(hash).to eq({ 'ping' => 'pong' })
        end
      end
    end
  end

  describe '::load_yaml_file_path' do
    context 'given ``file_path``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::YamlLoader.load_yaml_file_path(nil)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::YamlLoader.load_yaml_file_path(double('random'))
          }.to raise_error
        end
      end
      context 'is valid' do
        it 'get hash' do
          hash = AwsManager::Util::YamlLoader.load_yaml_file_path('valid_file_path')
          expect(hash).to eq({ 'ping' => 'pong' })
        end
      end
    end
  end
end
