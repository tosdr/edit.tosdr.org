require 'rails_helper'

RSpec.describe StringConverter do
  describe '#to_uuid' do
    it 'converts a valid url-safe annotation id to a UUID' do
      expect(described_class.new(string: '2AhKLMmLEe2_uVNBNy5wgA').to_uuid).to eq('d8084a2c-c98b-11ed-bfb9-5341372e7080')
    end

    it 'rejects decodable values that are not UUID-sized' do
      expect { described_class.new(string: 'AA').to_uuid }.to raise_error(ArgumentError, /16 bytes/)
    end
  end
end
