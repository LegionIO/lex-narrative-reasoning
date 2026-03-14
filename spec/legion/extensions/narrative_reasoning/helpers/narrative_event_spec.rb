# frozen_string_literal: true

RSpec.describe Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEvent do
  let(:event) do
    described_class.new(
      content:    'The detective discovers the clue',
      event_type: :discovery,
      characters: %w[detective suspect],
      causes:     [],
      domain:     'mystery'
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(event.content).to eq('The detective discovers the clue')
    end

    it 'stores event_type' do
      expect(event.event_type).to eq(:discovery)
    end

    it 'stores characters as array' do
      expect(event.characters).to contain_exactly('detective', 'suspect')
    end

    it 'stores causes' do
      expect(event.causes).to eq([])
    end

    it 'stores domain' do
      expect(event.domain).to eq('mystery')
    end

    it 'sets timestamp to now' do
      expect(event.timestamp).to be_a(Time)
    end

    it 'accepts explicit id' do
      custom = described_class.new(content: 'x', event_type: :action, id: 'custom-id')
      expect(custom.id).to eq('custom-id')
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = event.to_h
      expect(h[:id]).to eq(event.id)
      expect(h[:content]).to eq('The detective discovers the clue')
      expect(h[:event_type]).to eq(:discovery)
      expect(h[:characters]).to eq(%w[detective suspect])
      expect(h[:causes]).to eq([])
      expect(h[:domain]).to eq('mystery')
      expect(h[:timestamp]).to be_a(Time)
    end
  end
end
