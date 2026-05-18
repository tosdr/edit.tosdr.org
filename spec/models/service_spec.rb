# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Service, type: :model do
  it 'normalizes selected categories' do
    service = FactoryBot.build(:service, categories: ['', 'ai', 'file_sharing', 'ai'])

    expect(service).to be_valid
    expect(service.categories).to eq(%w[ai file_sharing])
  end

  it 'rejects unknown categories' do
    service = FactoryBot.build(:service, categories: ['unknown'])

    expect(service).not_to be_valid
    expect(service.errors[:categories]).to include('include unknown values: unknown')
  end

  it 'formats category labels for display' do
    expect(described_class.category_label('developer_tools')).to eq('Developer Tools')
    expect(described_class.category_label('search_engine')).to eq('Search Engine')
    expect(described_class.category_label('ai')).to eq('AI')
    expect(described_class.category_label('vpn')).to eq('VPN')
  end
end
