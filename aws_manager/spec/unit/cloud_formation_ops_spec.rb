require 'spec_helper'
require 'tempfile'

describe AwsManager::CloudFormationOps, unit: true do
  let(:hash) {
    { 'Environment' => 'environment',
      'Project'     => 'project',
      'Customer'    => 'customer' }
  }

  describe '::valid_parameters?' do
    context 'given `parameters`' do
      context 'is nil' do
        it 'raise error' do
          expect { AwsManager::CloudFormationOps.valid_parameters?(nil) }.to raise_error
        end
      end
      context "contains_not :'Environment'" do
        it 'returns false' do
          p = hash.reject { |k, _| k == 'Environment' }
          ecp = AwsManager::CloudFormationOps.valid_parameters?(p)
          expect(ecp).to be false
        end
      end
      context "contains_not :'Customer'" do
        it 'returns false' do
          p = hash.reject { |k, _| k == 'Customer' }
          ecp = AwsManager::CloudFormationOps.valid_parameters?(p)
          expect(ecp).to be false
        end
      end
      context "contains_not :'Project'" do
        it 'returns false' do
          p = hash.reject { |k, _| k == 'Project' }
          ecp = AwsManager::CloudFormationOps.valid_parameters?(p)
          expect(ecp).to be false
        end
      end
      context "contains :'Environment', :'Project' and :'Customer'" do
        it 'returns true' do
          ecp = AwsManager::CloudFormationOps.valid_parameters?(hash)
          expect(ecp).to be true
        end
      end
    end
  end

  describe '::valid_template_filename?' do
    let(:valid_filename) { 'environment_project_customer_component' }
    let(:invalid_filename) { 'x_y_z' }
    let(:generic_prefix_filename) { 'generic_customer_component' }
    context 'given `parameters`' do
      context 'is nil' do
        it 'raise error' do
          expect {
            AwsManager::CloudFormationOps.valid_template_filename?(valid_filename, nil)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `filename`' do
          context 'comforms_not to expected format' do
            it 'returns false' do
              r = AwsManager::CloudFormationOps
                  .valid_template_filename?(invalid_filename, hash)
              expect(r).to be false
            end
          end
          context 'conforms to expected format' do
            it 'returns true' do
              r = AwsManager::CloudFormationOps
                  .valid_template_filename?(valid_filename, hash)
              expect(r).to be true
            end
          end
        end
      end
    end
  end

  describe '::get_required_parameters' do
    let(:params) { { 'key' => 'value', 'key2' => 'value2' } }
    let(:missing_params) { { 'key' => 'value' } }
    let(:template) {
      { 'Parameters' => { 'key'  => { 'value'   => 'yek' },
                          'key2' => { 'value'   => '2yek',
                                      'Default' => 'default' }
                        }
      }
    }
    let(:template_no_default) {
      { 'Parameters' => { 'key'  => { 'value' => 'yek' },
                          'key2' => { 'value' => '2yek' }
                        }
      }
    }

    context 'given `parameters`' do
      context 'is nil' do
        it 'raise error' do
          expect{
            AwsManager::CloudFormationOps.get_required_parameters(nil, template)
          }.to raise_error
        end
      end
      context 'has missing parameters' do
        context 'given `template`' do
          context 'has_no default for the missing parameter' do
            it 'raise error' do
              expect {
                AwsManager::CloudFormationOps
                  .get_required_parameters(missing_params, template_no_default)
              }.to raise_error
            end
          end
          context 'has default for the missing parameter' do
            it 'returns the required parameters' do
              result = AwsManager::CloudFormationOps
                       .get_required_parameters(missing_params, template)
              expect(result.size).to eq(1)
              expect(result[0]).to include('parameter_key' => 'key', 'parameter_value' => 'value', 'use_previous_value' => false)
            end
          end
        end
      end
      context 'has no missing parameters' do
        context 'given `template`' do
          context 'is valid' do
            it 'returns the required parameters' do
              result = AwsManager::CloudFormationOps
                       .get_required_parameters(params, template)
              expect(result.size).to eq(2)
              expect(result[0]).to include('parameter_key' => 'key', 'parameter_value' => 'value', 'use_previous_value' => false)
              expect(result[1]).to include('parameter_key' => 'key2', 'parameter_value' => 'value2', 'use_previous_value' => false)
            end
          end
        end
      end
    end
  end

  describe '::get_component_name' do
    let(:filename) { 'customer_project_component' }
    let(:invalid_filename) { 'c_p_c' }
    let(:generic_filename) { 'generic_customer_component' }
    context 'given `parameters`' do
      context 'is nil' do
        it 'raise error' do
          expect {
            AwsManager::CloudFormationOps.get_component_name(nil, filename)
          }.to raise_error
        end
      end
      context "is missing :'Environment'" do
        it 'raise error' do
          p = hash.reject { |k, _| k == 'Environment' }
          expect {
            AwsManager::CloudFormationOps.get_component_name(p, nil)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `template_filename`' do
          context 'is nil' do
            it 'raise error' do
              expect {
                AwsManager::CloudFormationOps.get_component_name(hash, nil)
              }.to raise_error
            end
          end
          context 'is invalid' do
            it 'raise error' do
              expect {
                AwsManager::CloudFormationOps.get_component_name(hash, invalid_filename)
              }.to raise_error
            end
          end
          context 'contains generic prefix' do
            it 'returns component name' do
              r = AwsManager::CloudFormationOps.get_component_name(hash, generic_filename)
              expect(r).to eq('component')
            end
          end
          context 'is valid' do
            it 'returns component name' do
              r = AwsManager::CloudFormationOps.get_component_name(hash, filename)
              expect(r).to eq('component')
            end
          end
        end
      end
    end
  end

  describe '::generate_stack_name' do
    let(:filepath) { '/a/b/c/customer_project_component.json' }
    let(:invalid_filepath) { 'c_p_c' }
    let(:generic_filepath) { '/a/b/c/generic_customer_component.json' }
    context 'given `parameters`' do
      context 'is nil' do
        it 'raise error' do
          expect {
            AwsManager::CloudFormationOps.generate_stack_name(nil, filename)
          }.to raise_error
        end
      end
      context 'is missing :`Environment`' do
        it 'raise error' do
          p = hash.reject { |k, _| k == 'Environment' }
          expect {
            AwsManager::CloudFormationOps.generate_stack_name(p, filename)
          }.to raise_error
        end
      end
      context 'is valid' do
        context 'given `template_filepath`' do
          context 'is nil' do
            it 'raise error' do
              expect {
                AwsManager::CloudFormationOps.generate_stack_name(hash, nil)
              }.to raise_error
            end
          end
          context 'is invalid' do
            it 'raise error' do
              expect {
                AwsManager::CloudFormationOps.generate_stack_name(hash, invalid_filepath)
              }.to raise_error
            end
          end
          context 'is valid' do
            it 'returns stack name' do
              r = AwsManager::CloudFormationOps.generate_stack_name(hash, filepath)
              expect(r).to eq('environment-customer-project-component')
            end
          end
        end
      end
    end
  end
end
