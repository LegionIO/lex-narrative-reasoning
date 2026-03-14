# lex-narrative-reasoning

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-narrative-reasoning`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::NarrativeReasoning`

## Purpose

Story-structure reasoning engine for the cognitive architecture. Maintains a collection of narratives (each with a five-stage arc, coherence score, events, characters, and themes), supports causal chain tracing between events, and decays coherence over time to model narrative forgetting.

## Gem Info

- **Gemspec**: `lex-narrative-reasoning.gemspec`
- **Homepage**: https://github.com/LegionIO/lex-narrative-reasoning
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/narrative_reasoning/
  version.rb
  client.rb
  helpers/
    narrative.rb           # Narrative class — arc, coherence, events, characters, themes
    narrative_event.rb     # NarrativeEvent class — content, event_type, characters, causes
    narrative_engine.rb    # NarrativeEngine — store, eviction, decay, queries
  runners/
    narrative_reasoning.rb # Runner module — all public runner methods
spec/
  helpers/narrative_spec.rb
  helpers/narrative_event_spec.rb
  helpers/narrative_engine_spec.rb
  runners/narrative_reasoning_spec.rb
  client_spec.rb
```

## Key Constants

From `Helpers::Narrative`:
- `ARC_STAGES = %i[beginning rising_action climax falling_action resolution]`
- `DEFAULT_COHERENCE = 0.5`, `COHERENCE_BOOST = 0.1`, `DECAY_RATE = 0.02`
- `COHERENCE_LABELS`: ranges mapped to `:compelling`, `:coherent`, `:developing`, `:fragmented`, `:incoherent`

From `Helpers::NarrativeEngine`:
- `MAX_NARRATIVES = 100`, `MAX_EVENTS = 500`, `MAX_CHARACTERS = 200`
- `EVENT_TYPES = %i[action discovery conflict resolution revelation]`

## Runners

All methods are in `Runners::NarrativeReasoning` and delegated through the memoized `@narrative_engine` instance.

| Method | Key Parameters | Returns |
|---|---|---|
| `create_narrative` | `title:`, `domain:` | `{ narrative_id:, title:, arc_stage: }` |
| `add_narrative_event` | `narrative_id:`, `content:`, `event_type:`, `characters:`, `causes:` | `{ event_id:, event_type:, narrative_id: }` |
| `add_narrative_theme` | `narrative_id:`, `theme:` | `{ narrative_id:, theme: }` |
| `advance_narrative_arc` | `narrative_id:` | `{ arc_stage: }` |
| `trace_narrative_causes` | `narrative_id:` | `{ chain:, link_count: }` |
| `complete_narratives` | — | `{ narratives:, count: }` |
| `domain_narratives` | `domain:` | `{ narratives:, count: }` |
| `most_coherent_narratives` | `limit: 5` | `{ narratives:, count: }` |
| `update_narrative_reasoning` | — | tick decay cycle |
| `narrative_reasoning_stats` | — | `{ total_narratives:, total_events:, top_coherence: }` |

## Helpers

### `Helpers::Narrative`
Represents a single story. Auto-advances arc stage proportionally as events are added. Coherence rises +0.1 per event, decays -0.02 per tick. `complete?` returns true when `arc_stage == :resolution`. `causal_chain` walks `causes` arrays to build cause-effect pairs.

### `Helpers::NarrativeEvent`
Value object: `id`, `content`, `event_type`, `characters`, `causes` (list of event IDs), `domain`, `timestamp`.

### `Helpers::NarrativeEngine`
In-memory store (`@narratives` hash). Evicts oldest narrative at `MAX_NARRATIVES`. Evicts oldest event from a narrative at `MAX_EVENTS`. `decay_all` calls `decay_coherence` on every narrative. `most_coherent(limit:)` sorts by descending coherence. `by_domain` filters by domain.

## Integration Points

- Wired into `lex-tick` via `narrative_reasoning` phase handler key (when cortex assembles handlers)
- `update_narrative_reasoning` is called each tick to advance coherence decay
- `domain` field on narratives/events can correlate with `lex-memory` trace domains
- `causal_chain` output can inform `lex-prediction` about known cause-effect relationships

## Development Notes

- State is fully in-memory; reset on process restart
- `add_narrative_event` validates `event_type` against `EVENT_TYPES` before delegating; returns `{ success: false, error: :invalid_event_type }` on failure
- Arc auto-advancement is proportional: stage_idx = clamped(events.size / events_per_stage, max_stage)
- `Client` pre-instantiates `NarrativeEngine` in `initialize`; runner module uses `@narrative_engine` lazy accessor
