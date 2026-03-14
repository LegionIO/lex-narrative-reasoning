# lex-narrative-reasoning

Narrative reasoning engine for the LegionIO cognitive architecture. Maintains story structures with arc progression, causal chains, and coherence scoring.

## What It Does

Creates and tracks narratives — structured sequences of events with a five-stage arc (beginning, rising action, climax, falling action, resolution), causal links between events, characters, and themes. Coherence scores rise as events are added and decay over time, modeling how incomplete narratives fade. Causal chains can be traced to understand why events happened.

## Usage

```ruby
client = Legion::Extensions::NarrativeReasoning::Client.new

# Create a narrative
result = client.create_narrative(title: 'Infrastructure migration', domain: :engineering)
narrative_id = result[:narrative_id]

# Add events
client.add_narrative_event(
  narrative_id: narrative_id,
  content:      'Database cluster failed over to replica',
  event_type:   :conflict,
  characters:   ['db-primary', 'db-replica'],
  causes:       []
)

event_result = client.add_narrative_event(
  narrative_id: narrative_id,
  content:      'Traffic rerouted successfully',
  event_type:   :resolution,
  characters:   ['load-balancer'],
  causes:       [event_id_of_failover]
)

# Trace what caused what
client.trace_narrative_causes(narrative_id: narrative_id)
# => { chain: [{ cause: { content: 'failed over...' }, effect: { content: 'rerouted...' } }], link_count: 1 }

# Arc progression
client.advance_narrative_arc(narrative_id: narrative_id)

# Stats
client.narrative_reasoning_stats
# => { total_narratives: 1, total_events: 2, top_coherence: 0.7, top_coherence_label: :coherent }
```

## Event Types

`:action`, `:discovery`, `:conflict`, `:resolution`, `:revelation`

## Arc Stages

`:beginning` -> `:rising_action` -> `:climax` -> `:falling_action` -> `:resolution`

Arc advances automatically as events accumulate. A narrative is complete when it reaches `:resolution`.

## Coherence Labels

| Range | Label |
|---|---|
| 0.8+ | `:compelling` |
| 0.6–0.8 | `:coherent` |
| 0.4–0.6 | `:developing` |
| 0.2–0.4 | `:fragmented` |
| < 0.2 | `:incoherent` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
