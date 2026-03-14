# frozen_string_literal: true

RSpec.describe Legion::Extensions::NarrativeReasoning::Helpers::Narrative do
  let(:narrative) { described_class.new(title: 'The Journey', domain: 'adventure') }

  let(:event1) do
    Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEvent.new(
      content:    'Hero leaves home',
      event_type: :action,
      characters: ['hero']
    )
  end

  let(:event2) do
    Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEvent.new(
      content:    'Hero discovers map',
      event_type: :discovery,
      characters: ['hero'],
      causes:     [event1.id]
    )
  end

  describe '#initialize' do
    it 'assigns id, title, domain' do
      expect(narrative.id).to match(/\A[0-9a-f-]{36}\z/)
      expect(narrative.title).to eq('The Journey')
      expect(narrative.domain).to eq('adventure')
    end

    it 'starts at beginning arc stage' do
      expect(narrative.arc_stage).to eq(:beginning)
    end

    it 'starts with default coherence' do
      expect(narrative.coherence).to eq(described_class::DEFAULT_COHERENCE)
    end

    it 'starts with empty events, characters, themes' do
      expect(narrative.events).to be_empty
      expect(narrative.characters).to be_empty
      expect(narrative.themes).to be_empty
    end
  end

  describe '#add_event' do
    it 'appends the event' do
      narrative.add_event(event1)
      expect(narrative.events).to include(event1)
    end

    it 'collects unique characters' do
      narrative.add_event(event1)
      narrative.add_event(event2)
      expect(narrative.characters).to contain_exactly('hero')
    end

    it 'boosts coherence on each event' do
      initial = narrative.coherence
      narrative.add_event(event1)
      expect(narrative.coherence).to be > initial
    end

    it 'does not exceed coherence ceiling' do
      15.times { narrative.add_event(event1) }
      expect(narrative.coherence).to be <= described_class::COHERENCE_CEILING
    end

    it 'updates last_updated_at' do
      before = narrative.last_updated_at
      sleep(0.01)
      narrative.add_event(event1)
      expect(narrative.last_updated_at).to be >= before
    end
  end

  describe '#add_theme' do
    it 'adds a theme' do
      narrative.add_theme('redemption')
      expect(narrative.themes).to include('redemption')
    end

    it 'does not add duplicate themes' do
      narrative.add_theme('redemption')
      narrative.add_theme('redemption')
      expect(narrative.themes.count('redemption')).to eq(1)
    end
  end

  describe '#advance_arc!' do
    it 'advances to next arc stage' do
      narrative.advance_arc!
      expect(narrative.arc_stage).to eq(:rising_action)
    end

    it 'does not advance past resolution' do
      5.times { narrative.advance_arc! }
      expect(narrative.arc_stage).to eq(:resolution)
      narrative.advance_arc!
      expect(narrative.arc_stage).to eq(:resolution)
    end
  end

  describe '#causal_chain' do
    it 'returns empty with no causes' do
      narrative.add_event(event1)
      expect(narrative.causal_chain).to be_empty
    end

    it 'returns cause->effect links' do
      narrative.add_event(event1)
      narrative.add_event(event2)
      chain = narrative.causal_chain
      expect(chain.size).to eq(1)
      expect(chain.first[:cause][:id]).to eq(event1.id)
      expect(chain.first[:effect][:id]).to eq(event2.id)
    end
  end

  describe '#coherence_label' do
    it 'returns :developing for default coherence' do
      expect(narrative.coherence_label).to eq(:developing)
    end

    it 'returns :compelling for high coherence' do
      10.times { narrative.add_event(event1) }
      expect(narrative.coherence_label).to eq(:compelling)
    end
  end

  describe '#complete?' do
    it 'returns false at start' do
      expect(narrative.complete?).to be false
    end

    it 'returns true at resolution' do
      5.times { narrative.advance_arc! }
      expect(narrative.complete?).to be true
    end
  end

  describe '#decay_coherence' do
    it 'reduces coherence by DECAY_RATE' do
      before = narrative.coherence
      narrative.decay_coherence
      expect(narrative.coherence).to be_within(0.001).of(before - described_class::DECAY_RATE)
    end

    it 'does not go below coherence floor' do
      200.times { narrative.decay_coherence }
      expect(narrative.coherence).to eq(described_class::COHERENCE_FLOOR)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = narrative.to_h
      expect(h).to include(:id, :title, :domain, :events, :characters, :themes,
                           :arc_stage, :coherence, :coherence_label, :complete,
                           :created_at, :last_updated_at)
    end
  end

  describe 'ARC_STAGES constant' do
    it 'contains the five expected stages in order' do
      expect(described_class::ARC_STAGES).to eq(%i[beginning rising_action climax falling_action resolution])
    end
  end
end
