# frozen_string_literal: true

module Legion
  module Extensions
    module NarrativeReasoning
      module Helpers
        class NarrativeEngine
          MAX_NARRATIVES = 100
          MAX_EVENTS     = 500
          MAX_CHARACTERS = 200
          MAX_HISTORY    = 300

          EVENT_TYPES = %i[action discovery conflict resolution revelation].freeze

          def initialize
            @narratives = {}
            @event_count = 0
          end

          def create_narrative(title:, domain: nil)
            evict_oldest_narrative if @narratives.size >= MAX_NARRATIVES
            narrative = Narrative.new(title: title, domain: domain)
            @narratives[narrative.id] = narrative
            narrative
          end

          def add_narrative_event(narrative_id:, content:, event_type:, characters: [], causes: [])
            narrative = @narratives[narrative_id]
            return nil unless narrative
            return nil unless EVENT_TYPES.include?(event_type)

            domain = narrative.domain
            event = NarrativeEvent.new(
              content:    content,
              event_type: event_type,
              characters: characters,
              causes:     causes,
              domain:     domain
            )
            @event_count += 1
            evict_oldest_events(narrative) if narrative.events.size >= MAX_EVENTS
            narrative.add_event(event)
          end

          def add_narrative_theme(narrative_id:, theme:)
            narrative = @narratives[narrative_id]
            return nil unless narrative

            narrative.add_theme(theme)
          end

          def advance_narrative(narrative_id:)
            narrative = @narratives[narrative_id]
            return nil unless narrative

            narrative.advance_arc!
          end

          def trace_causal_chain(narrative_id:)
            narrative = @narratives[narrative_id]
            return [] unless narrative

            narrative.causal_chain
          end

          def complete_narratives
            @narratives.values.select(&:complete?)
          end

          def by_domain(domain:)
            @narratives.values.select { |n| n.domain == domain }
          end

          def most_coherent(limit: 5)
            @narratives.values
                       .sort_by { |n| -n.coherence }
                       .first(limit)
          end

          def get(narrative_id)
            @narratives[narrative_id]
          end

          def decay_all
            @narratives.each_value(&:decay_coherence)
          end

          def count
            @narratives.size
          end

          def total_events
            @event_count
          end

          def to_h
            {
              narratives:   @narratives.values.map(&:to_h),
              count:        @narratives.size,
              total_events: @event_count
            }
          end

          private

          def evict_oldest_narrative
            oldest = @narratives.values.min_by(&:created_at)
            @narratives.delete(oldest.id) if oldest
          end

          def evict_oldest_events(narrative)
            narrative.events.shift
          end
        end
      end
    end
  end
end
