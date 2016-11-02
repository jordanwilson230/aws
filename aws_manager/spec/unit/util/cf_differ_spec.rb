require 'spec_helper'

describe AwsManager::Util::CloudFormationDiffer, unit: true do
  # Unit test for: def self.diff_files(file_source_path, file_target_path)
  describe '::diff_files' do
    before do
      allow(File).to receive(:read).with(anything).and_raise('error')
      allow(File).to receive(:read).with('valid_file_source_path') { 'File Content\n' }
      allow(File).to receive(:read).with('valid_file_target_path') { 'File Content\n' }
    end
    context 'given ``file_source_path``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.diff_files(nil, 'valid_file_target_path')
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.diff_files(double('random'), 'valid_file_target_path')
          }.to raise_error
        end
      end
      context 'is random string' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.diff_files('minbhmiarjfenql9', 'valid_file_target_path')
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given ``file_target_path``' do
          context 'is nil' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.diff_files('valid_file_source_path', nil)
              }.to raise_error
            end
          end
          context 'is random object' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.diff_files('valid_file_source_path', double('random'))
              }.to raise_error
            end
          end
          context 'is random string' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.diff_files('valid_file_source_path', 'minbhmiarjfenql9')
              }.to raise_error
            end
          end
          context 'is valid' do
            it 'receive text' do
              content = AwsManager::Util::CloudFormationDiffer.diff_files('valid_file_source_path', 'valid_file_target_path')
              expect(content).to eq('')
            end
          end
        end
      end
    end
  end

  # Unit test for: def self.diff_templates(remote_template, local_template)
  describe '::diff_templates' do
    let(:valid_local_template) { '{}' }
    let(:valid_remote_template) { '{}' }

    context 'given ``remote_template``' do
      context 'is valid' do
        context 'given ``local_template``' do
          context 'is valid' do
            it 'receive boolean' do
              content = AwsManager::Util::CloudFormationDiffer.diff_templates(valid_remote_template, valid_local_template)
              expect(content).to eq(false)
            end
          end
        end
      end
    end
  end

  # Unit test for: def self.diff_params(remote_params, local_params, ignore_params)
  describe '::diff_params' do
    let(:valid_remote_params) { [{ 'parameter_key' => 'k1', 'parameter_value' => 'v1' }, { 'parameter_key' => 'k2', 'parameter_value' => 'v2' }] }
    let(:valid_local_params) { [{ 'parameter_key' => 'k1', 'parameter_value' => 'v1' }, { 'parameter_key' => 'k2', 'parameter_value' => 'v22' }] }
    let(:valid_ignore_params) { ['k2'] }

    context 'given ``remote_params``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.diff_params(nil, valid_local_params, valid_ignore_params)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.diff_params(double('random'), valid_local_params, valid_ignore_params)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given ``local_params``' do
          context 'is nil' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.diff_params(valid_remote_params, nil, valid_ignore_params)
              }.to raise_error
            end
          end
          context 'is random object' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.diff_params(valid_remote_params, double('random'), valid_ignore_params)
              }.to raise_error
            end
          end
          context 'is valid' do
            context 'given ``ignore_params``' do
              context 'is nil' do
                it 'raise error' do
                  expect{
                    AwsManager::Util::CloudFormationDiffer.diff_params(valid_remote_params, nil, valid_ignore_params)
                  }.to raise_error
                end
              end
              context 'is random object' do
                it 'raise error' do
                  expect{
                    AwsManager::Util::CloudFormationDiffer.diff_params(valid_remote_params, double('random'), valid_ignore_params)
                  }.to raise_error
                end
              end
              context 'is valid' do
                it 'receive boolean' do
                  content = AwsManager::Util::CloudFormationDiffer.diff_params(valid_remote_params, valid_local_params, valid_ignore_params)
                  expect(content).to eq(false)
                end
              end
            end
          end
        end
      end
    end
  end

  # Unit test for: def self.array_to_string(array_input, delimiter = '\n')
  describe '::array_to_string' do
    let(:valid_array_input) { ['line1', 'line2', 'line3'] }
    let(:valid_result) { "line1\nline2\nline3\n" }

    context 'given ``array_input``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.array_to_string(nil)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.array_to_string(double('random'))
          }.to raise_error
        end
      end
      context 'is valid' do
        it 'receive text' do
          content = AwsManager::Util::CloudFormationDiffer.array_to_string(valid_array_input)
          expect(content).to eq(valid_result)
        end
      end
    end
  end

  # Unit test for: def self.fill_params_with_default_values(remote_params, local_params)
  describe '::fill_params_with_default_values' do
    let(:valid_remote_params) { [{ 'parameter_key' => 'k1', 'parameter_value' => 'v1' }, { 'parameter_key' => 'k2', 'parameter_value' => 'v2' }] }
    let(:valid_local_params) { [{ 'parameter_key' => 'k1', 'parameter_value' => 'v1' }] }
    let(:valid_result) { [{ 'parameter_key' => 'k1', 'parameter_value' => 'v1' }, { 'parameter_key' => 'k2', 'parameter_value' => 'v2' }] }

    context 'given ``remote_params``' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.fill_params_with_default_values(nil, valid_local_params)
          }.to raise_error
        end
      end
      context 'is random object' do
        it 'raise error' do
          expect{
            AwsManager::Util::CloudFormationDiffer.fill_params_with_default_values(double('random'), valid_local_params)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given ``local_params``' do
          context 'is nil' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.fill_params_with_default_values(valid_remote_params, nil)
              }.to raise_error
            end
          end
          context 'is random object' do
            it 'raise error' do
              expect{
                AwsManager::Util::CloudFormationDiffer.fill_params_with_default_values(valid_remote_params, double('random'))
              }.to raise_error
            end
          end
          context 'is valid' do
            context 'is valid' do
              it 'receive array' do
                content = AwsManager::Util::CloudFormationDiffer.fill_params_with_default_values(valid_remote_params, valid_local_params)
                expect(content).to eq(valid_result)
              end
            end
          end
        end
      end
    end
  end
end
