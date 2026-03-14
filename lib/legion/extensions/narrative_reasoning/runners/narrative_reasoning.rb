# frozen_string_literal: true

module Legion
  module Extensions
    module NarrativeReasoning
      module Runners
        module NarrativeReasoning
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_narrative(title:, domain: nil, **)
            narrative = narrative_engine.create_narrative(title: title, domain: domain)
            Legion::Logging.debug "[narrative_reasoning] created narrative id=#{narrative.id[0..7]} title=#{title}"
            { success: true, narrative_id: narrative.id, title: narrative.title, arc_stage: narrative.arc_stage }
          end

          def add_narrative_event(narrative_id:, content:, event_type:, characters: [], causes: [], **)
            unless Helpers::NarrativeEngine::EVENT_TYPES.include?(event_type)
              return { success: false, error: :invalid_event_type, valid_types: Helpers::NarrativeEngine::EVENT_TYPES }
            end

            event = narrative_engine.add_narrative_event(
              narrative_id: narrative_id,
              content:      content,
              event_type:   event_type,
              characters:   characters,
              causes:       causes
            )

            if event
              Legion::Logging.debug "[narrative_reasoning] event added id=#{event.id[0..7]} type=#{event_type}"
              { success: true, event_id: event.id, event_type: event_type, narrative_id: narrative_id }
            else
              Legion::Logging.debug "[narrative_reasoning] add_event failed: narrative #{narrative_id[0..7]} not found"
              { success: false, error: :narrative_not_found }
            end
          end

          def add_narrative_theme(narrative_id:, theme:, **)
            result = narrative_engine.add_narrative_theme(narrative_id: narrative_id, theme: theme)
            if result
              Legion::Logging.debug "[narrative_reasoning] theme added theme=#{theme} to #{narrative_id[0..7]}"
              { success: true, narrative_id: narrative_id, theme: theme }
            else
              { success: false, error: :narrative_not_found }
            end
          end

          def advance_narrative_arc(narrative_id:, **)
            new_stage = narrative_engine.advance_narrative(narrative_id: narrative_id)
            if new_stage
              Legion::Logging.debug "[narrative_reasoning] arc advanced to #{new_stage} for #{narrative_id[0..7]}"
              { success: true, narrative_id: narrative_id, arc_stage: new_stage }
            else
              { success: false, error: :narrative_not_found }
            end
          end

          def trace_narrative_causes(narrative_id:, **)
            chain = narrative_engine.trace_causal_chain(narrative_id: narrative_id)
            narrative = narrative_engine.get(narrative_id)
            return { success: false, error: :narrative_not_found } unless narrative

            Legion::Logging.debug "[narrative_reasoning] causal chain length=#{chain.size} for #{narrative_id[0..7]}"
            { success: true, narrative_id: narrative_id, chain: chain, link_count: chain.size }
          end

          def complete_narratives(**)
            narratives = narrative_engine.complete_narratives
            Legion::Logging.debug "[narrative_reasoning] complete narratives count=#{narratives.size}"
            { success: true, narratives: narratives.map(&:to_h), count: narratives.size }
          end

          def domain_narratives(domain:, **)
            narratives = narrative_engine.by_domain(domain: domain)
            Legion::Logging.debug "[narrative_reasoning] domain=#{domain} count=#{narratives.size}"
            { success: true, domain: domain, narratives: narratives.map(&:to_h), count: narratives.size }
          end

          def most_coherent_narratives(limit: 5, **)
            lim = limit.to_i.clamp(1, 50)
            narratives = narrative_engine.most_coherent(limit: lim)
            Legion::Logging.debug "[narrative_reasoning] most_coherent limit=#{lim} returned=#{narratives.size}"
            { success: true, narratives: narratives.map(&:to_h), count: narratives.size }
          end

          def update_narrative_reasoning(**)
            narrative_engine.decay_all
            count = narrative_engine.count
            Legion::Logging.debug "[narrative_reasoning] decay cycle complete narratives=#{count}"
            { success: true, narratives_updated: count }
          end

          def narrative_reasoning_stats(**)
            engine = narrative_engine
            complete = engine.complete_narratives.size
            most_coh = engine.most_coherent(limit: 1).first
            Legion::Logging.debug "[narrative_reasoning] stats count=#{engine.count} complete=#{complete}"
            {
              success:             true,
              total_narratives:    engine.count,
              total_events:        engine.total_events,
              complete_narratives: complete,
              top_coherence:       most_coh&.coherence,
              top_coherence_label: most_coh&.coherence_label
            }
          end

          private

          def narrative_engine
            @narrative_engine ||= Helpers::NarrativeEngine.new
          end
        end
      end
    end
  end
end
