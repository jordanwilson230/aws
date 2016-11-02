require 'spec_helper'

describe AwsManager::Route53, unit: true do
  let(:route53) {
    allow(System).to receive(:get_ifaddrs) { ifaddrs }
    pageable_response = double('pageable response')
    change_hash = double('change hash', id: '123456')
    allow(change_hash).to receive(:[])
      .with(:id) { change_id }
    allow(pageable_response).to receive(:[])
      .with(:change_info) { change_hash }
    aws_route53 = double('aws_route53')
    allow(aws_route53).to receive(:change_resource_record_sets)
      .with(hash_including(hosted_zone_id: zone_id)) { pageable_response }

    AwsManager::Route53.new(aws_route53)
  }

  let(:ifaddrs) { { eth0: { inet_addr: '10.10.10.10', netmask: '255.0.0.0' } } }
  let(:action) { 'CREATE' }
  let(:zone_id) { 'good_zone_id' }
  let(:invalid_zone_id) { 'invalid_zone_id' }
  let(:domain_name) { 'good_domain_name' }
  let(:invalid_domain_name) { 'invalid_domain_name' }
  let(:record_set_name) { 'good_record_set_name' }
  let(:invalid_record_set_name) { 'invalid_record_set_name' }
  let(:interface) { 'eth0' }
  let(:invalid_interface) { 'XX0' }
  let(:change_id) { '123456' }

  describe '#change_record_set' do
    context 'given `hosted_zone_id`' do
      context 'is invalid' do
        it 'raise error' do
          expect { route53.change_record_set(action, invalid_zone_id, domain_name, record_set_name, interface) }.to raise_error
        end
      end
      context 'is valid' do
        it 'returns pageable response' do
          response = route53.change_record_set(action, zone_id, domain_name, record_set_name, interface)
          expect(response).to eq(change_id)
        end
      end
    end
  end
end
