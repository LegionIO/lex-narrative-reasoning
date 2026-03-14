# frozen_string_literal: true

require 'legion/extensions/narrative_reasoning/client'

RSpec.describe Legion::Extensions::NarrativeReasoning::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_narrative)
    expect(client).to respond_to(:add_narrative_event)
    expect(client).to respond_to(:add_narrative_theme)
    expect(client).to respond_to(:advance_narrative_arc)
    expect(client).to respond_to(:trace_narrative_causes)
    expect(client).to respond_to(:complete_narratives)
    expect(client).to respond_to(:domain_narratives)
    expect(client).to respond_to(:most_coherent_narratives)
    expect(client).to respond_to(:update_narrative_reasoning)
    expect(client).to respond_to(:narrative_reasoning_stats)
  end
end
