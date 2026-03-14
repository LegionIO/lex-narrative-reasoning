# frozen_string_literal: true

RSpec.describe Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEngine do
  let(:engine) { described_class.new }

  describe '#create_narrative' do
    it 'creates a new narrative' do
      narrative = engine.create_narrative(title: 'Test Story', domain: 'test')
      expect(narrative).to be_a(Legion::Extensions::NarrativeReasoning::Helpers::Narrative)
      expect(narrative.title).to eq('Test Story')
      expect(narrative.domain).to eq('test')
    end

    it 'stores the narrative' do
      narrative = engine.create_narrative(title: 'Stored')
      expect(engine.get(narrative.id)).to eq(narrative)
    end

    it 'increments count' do
      engine.create_narrative(title: 'First')
      engine.create_narrative(title: 'Second')
      expect(engine.count).to eq(2)
    end
  end

  describe '#add_narrative_event' do
    let(:narrative) { engine.create_narrative(title: 'Events Test') }

    it 'adds an event to the narrative' do
      event = engine.add_narrative_event(
        narrative_id: narrative.id,
        content:      'Something happened',
        event_type:   :action
      )
      expect(event).to be_a(Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEvent)
      expect(narrative.events.size).to eq(1)
    end

    it 'returns nil for unknown narrative' do
      result = engine.add_narrative_event(
        narrative_id: 'no-such-id',
        content:      'x',
        event_type:   :action
      )
      expect(result).to be_nil
    end

    it 'returns nil for invalid event_type' do
      result = engine.add_narrative_event(
        narrative_id: narrative.id,
        content:      'x',
        event_type:   :invalid_type
      )
      expect(result).to be_nil
    end

    it 'tracks total_events count' do
      engine.add_narrative_event(narrative_id: narrative.id, content: 'a', event_type: :action)
      engine.add_narrative_event(narrative_id: narrative.id, content: 'b', event_type: :conflict)
      expect(engine.total_events).to eq(2)
    end

    it 'accepts all valid event types' do
      described_class::EVENT_TYPES.each do |type|
        result = engine.add_narrative_event(narrative_id: narrative.id, content: 'x', event_type: type)
        expect(result).not_to be_nil
      end
    end
  end

  describe '#add_narrative_theme' do
    let(:narrative) { engine.create_narrative(title: 'Theme Test') }

    it 'adds a theme to the narrative' do
      engine.add_narrative_theme(narrative_id: narrative.id, theme: 'identity')
      expect(narrative.themes).to include('identity')
    end

    it 'returns nil for unknown narrative' do
      result = engine.add_narrative_theme(narrative_id: 'unknown', theme: 'x')
      expect(result).to be_nil
    end
  end

  describe '#advance_narrative' do
    let(:narrative) { engine.create_narrative(title: 'Arc Test') }

    it 'advances arc stage' do
      new_stage = engine.advance_narrative(narrative_id: narrative.id)
      expect(new_stage).to eq(:rising_action)
    end

    it 'returns nil for unknown narrative' do
      result = engine.advance_narrative(narrative_id: 'bad')
      expect(result).to be_nil
    end
  end

  describe '#trace_causal_chain' do
    let(:narrative) { engine.create_narrative(title: 'Causal Test') }

    it 'returns empty array for narrative with no causes' do
      engine.add_narrative_event(narrative_id: narrative.id, content: 'start', event_type: :action)
      chain = engine.trace_causal_chain(narrative_id: narrative.id)
      expect(chain).to be_empty
    end

    it 'returns causal links when events have causes' do
      evt1 = engine.add_narrative_event(narrative_id: narrative.id, content: 'start', event_type: :action)
      engine.add_narrative_event(
        narrative_id: narrative.id,
        content:      'consequence',
        event_type:   :resolution,
        causes:       [evt1.id]
      )
      chain = engine.trace_causal_chain(narrative_id: narrative.id)
      expect(chain.size).to eq(1)
    end

    it 'returns empty array for unknown narrative' do
      expect(engine.trace_causal_chain(narrative_id: 'nope')).to eq([])
    end
  end

  describe '#complete_narratives' do
    it 'returns narratives at resolution stage' do
      n1 = engine.create_narrative(title: 'Finished')
      5.times { n1.advance_arc! }
      engine.create_narrative(title: 'In Progress')
      expect(engine.complete_narratives).to include(n1)
      expect(engine.complete_narratives.size).to eq(1)
    end
  end

  describe '#by_domain' do
    it 'returns narratives matching domain' do
      engine.create_narrative(title: 'A', domain: 'sci-fi')
      engine.create_narrative(title: 'B', domain: 'sci-fi')
      engine.create_narrative(title: 'C', domain: 'mystery')
      expect(engine.by_domain(domain: 'sci-fi').size).to eq(2)
    end
  end

  describe '#most_coherent' do
    it 'returns narratives sorted by coherence descending' do
      engine.create_narrative(title: 'Low')
      high = engine.create_narrative(title: 'High')
      5.times { high.add_event(Legion::Extensions::NarrativeReasoning::Helpers::NarrativeEvent.new(content: 'x', event_type: :action)) }
      result = engine.most_coherent(limit: 2)
      expect(result.first).to eq(high)
    end

    it 'respects the limit' do
      3.times { |i| engine.create_narrative(title: "N#{i}") }
      expect(engine.most_coherent(limit: 2).size).to be <= 2
    end
  end

  describe '#decay_all' do
    it 'reduces coherence of all narratives' do
      n = engine.create_narrative(title: 'Decay Test')
      before = n.coherence
      engine.decay_all
      expect(n.coherence).to be < before
    end
  end

  describe '#to_h' do
    it 'includes count and narratives array' do
      engine.create_narrative(title: 'One')
      h = engine.to_h
      expect(h[:count]).to eq(1)
      expect(h[:narratives]).to be_an(Array)
    end
  end

  describe 'EVENT_TYPES constant' do
    it 'includes the five required types' do
      expect(described_class::EVENT_TYPES).to include(:action, :discovery, :conflict, :resolution, :revelation)
    end
  end
end
