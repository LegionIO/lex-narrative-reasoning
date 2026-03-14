# frozen_string_literal: true

require 'legion/extensions/narrative_reasoning/client'

RSpec.describe Legion::Extensions::NarrativeReasoning::Runners::NarrativeReasoning do
  let(:client) { Legion::Extensions::NarrativeReasoning::Client.new }

  describe '#create_narrative' do
    it 'returns success with narrative_id and title' do
      result = client.create_narrative(title: 'My Story', domain: 'fantasy')
      expect(result[:success]).to be true
      expect(result[:narrative_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:title]).to eq('My Story')
      expect(result[:arc_stage]).to eq(:beginning)
    end
  end

  describe '#add_narrative_event' do
    let(:narrative_id) { client.create_narrative(title: 'Event Test')[:narrative_id] }

    it 'adds an event and returns event_id' do
      result = client.add_narrative_event(
        narrative_id: narrative_id,
        content:      'Hero acts',
        event_type:   :action,
        characters:   ['hero']
      )
      expect(result[:success]).to be true
      expect(result[:event_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns error for unknown narrative' do
      result = client.add_narrative_event(narrative_id: 'bad', content: 'x', event_type: :action)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:narrative_not_found)
    end

    it 'returns error for invalid event_type' do
      result = client.add_narrative_event(narrative_id: narrative_id, content: 'x', event_type: :bogus)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_event_type)
    end
  end

  describe '#add_narrative_theme' do
    let(:narrative_id) { client.create_narrative(title: 'Theme Test')[:narrative_id] }

    it 'adds a theme successfully' do
      result = client.add_narrative_theme(narrative_id: narrative_id, theme: 'courage')
      expect(result[:success]).to be true
      expect(result[:theme]).to eq('courage')
    end

    it 'returns error for unknown narrative' do
      result = client.add_narrative_theme(narrative_id: 'nope', theme: 'x')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:narrative_not_found)
    end
  end

  describe '#advance_narrative_arc' do
    let(:narrative_id) { client.create_narrative(title: 'Arc Test')[:narrative_id] }

    it 'advances to next arc stage' do
      result = client.advance_narrative_arc(narrative_id: narrative_id)
      expect(result[:success]).to be true
      expect(result[:arc_stage]).to eq(:rising_action)
    end

    it 'returns error for unknown narrative' do
      result = client.advance_narrative_arc(narrative_id: 'bad')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:narrative_not_found)
    end
  end

  describe '#trace_narrative_causes' do
    let(:narrative_id) { client.create_narrative(title: 'Causal Test')[:narrative_id] }

    it 'returns empty chain with no causes' do
      client.add_narrative_event(narrative_id: narrative_id, content: 'start', event_type: :action)
      result = client.trace_narrative_causes(narrative_id: narrative_id)
      expect(result[:success]).to be true
      expect(result[:chain]).to eq([])
      expect(result[:link_count]).to eq(0)
    end

    it 'returns causal links' do
      evt = client.add_narrative_event(narrative_id: narrative_id, content: 'cause', event_type: :action)
      client.add_narrative_event(
        narrative_id: narrative_id,
        content:      'effect',
        event_type:   :resolution,
        causes:       [evt[:event_id]]
      )
      result = client.trace_narrative_causes(narrative_id: narrative_id)
      expect(result[:link_count]).to eq(1)
    end

    it 'returns error for unknown narrative' do
      result = client.trace_narrative_causes(narrative_id: 'nope')
      expect(result[:success]).to be false
    end
  end

  describe '#complete_narratives' do
    it 'returns empty list when none are complete' do
      client.create_narrative(title: 'Incomplete')
      result = client.complete_narratives
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'includes narratives that reached resolution' do
      nid = client.create_narrative(title: 'Done')[:narrative_id]
      5.times { client.advance_narrative_arc(narrative_id: nid) }
      result = client.complete_narratives
      expect(result[:count]).to eq(1)
    end
  end

  describe '#domain_narratives' do
    it 'filters by domain' do
      client.create_narrative(title: 'A', domain: 'sci-fi')
      client.create_narrative(title: 'B', domain: 'sci-fi')
      client.create_narrative(title: 'C', domain: 'horror')
      result = client.domain_narratives(domain: 'sci-fi')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end
  end

  describe '#most_coherent_narratives' do
    it 'returns up to limit narratives' do
      3.times { |i| client.create_narrative(title: "N#{i}") }
      result = client.most_coherent_narratives(limit: 2)
      expect(result[:success]).to be true
      expect(result[:narratives].size).to be <= 2
    end

    it 'clamps limit to minimum 1' do
      client.create_narrative(title: 'Solo')
      result = client.most_coherent_narratives(limit: 0)
      expect(result[:narratives].size).to be >= 1
    end
  end

  describe '#update_narrative_reasoning' do
    it 'returns success with count of updated narratives' do
      client.create_narrative(title: 'A')
      client.create_narrative(title: 'B')
      result = client.update_narrative_reasoning
      expect(result[:success]).to be true
      expect(result[:narratives_updated]).to eq(2)
    end
  end

  describe '#narrative_reasoning_stats' do
    it 'returns stats hash' do
      client.create_narrative(title: 'Stats Test')
      result = client.narrative_reasoning_stats
      expect(result[:success]).to be true
      expect(result[:total_narratives]).to eq(1)
      expect(result[:total_events]).to be_a(Integer)
      expect(result[:complete_narratives]).to be_a(Integer)
    end

    it 'reports top_coherence_label' do
      client.create_narrative(title: 'Some Narrative')
      result = client.narrative_reasoning_stats
      expect(%i[compelling coherent developing fragmented incoherent]).to include(result[:top_coherence_label])
    end
  end
end
