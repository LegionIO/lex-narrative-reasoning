# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module NarrativeReasoning
      module Helpers
        class Narrative
          ARC_STAGES = %i[beginning rising_action climax falling_action resolution].freeze

          COHERENCE_LABELS = {
            (0.8..)     => :compelling,
            (0.6...0.8) => :coherent,
            (0.4...0.6) => :developing,
            (0.2...0.4) => :fragmented,
            (..0.2)     => :incoherent
          }.freeze

          DEFAULT_COHERENCE  = 0.5
          COHERENCE_FLOOR    = 0.0
          COHERENCE_CEILING  = 1.0
          COHERENCE_BOOST    = 0.1
          DECAY_RATE         = 0.02

          attr_reader :id, :title, :domain, :events, :characters, :themes,
                      :arc_stage, :coherence, :created_at, :last_updated_at

          def initialize(title:, domain: nil, id: nil)
            @id             = id || SecureRandom.uuid
            @title          = title
            @domain         = domain
            @events         = []
            @characters     = []
            @themes         = []
            @arc_stage      = ARC_STAGES.first
            @coherence      = DEFAULT_COHERENCE
            @created_at     = Time.now.utc
            @last_updated_at = Time.now.utc
          end

          def add_event(event)
            @events << event
            event.characters.each { |chr| @characters << chr unless @characters.include?(chr) }
            auto_advance_arc
            @coherence = (@coherence + COHERENCE_BOOST).clamp(COHERENCE_FLOOR, COHERENCE_CEILING)
            @last_updated_at = Time.now.utc
            event
          end

          def add_theme(theme)
            @themes << theme unless @themes.include?(theme)
            @last_updated_at = Time.now.utc
            theme
          end

          def advance_arc!
            idx = ARC_STAGES.index(@arc_stage)
            return @arc_stage if idx.nil? || idx >= ARC_STAGES.size - 1

            @arc_stage = ARC_STAGES[idx + 1]
            @last_updated_at = Time.now.utc
            @arc_stage
          end

          def causal_chain
            chain = []
            @events.each do |event|
              event.causes.each do |cause_id|
                cause = @events.find { |e| e.id == cause_id }
                chain << { cause: cause&.to_h, effect: event.to_h } if cause
              end
            end
            chain
          end

          def coherence_label
            COHERENCE_LABELS.find { |range, _label| range.cover?(@coherence) }&.last || :incoherent
          end

          def complete?
            @arc_stage == :resolution
          end

          def decay_coherence
            @coherence = (@coherence - DECAY_RATE).clamp(COHERENCE_FLOOR, COHERENCE_CEILING)
          end

          def to_h
            {
              id:              @id,
              title:           @title,
              domain:          @domain,
              events:          @events.map(&:to_h),
              characters:      @characters,
              themes:          @themes,
              arc_stage:       @arc_stage,
              coherence:       @coherence,
              coherence_label: coherence_label,
              complete:        complete?,
              created_at:      @created_at,
              last_updated_at: @last_updated_at
            }
          end

          private

          def auto_advance_arc
            return if complete?

            events_per_stage = [(@events.size / 5.0).ceil, 1].max
            stage_idx = [(@events.size / events_per_stage), ARC_STAGES.size - 1].min
            @arc_stage = ARC_STAGES[stage_idx]
          end
        end
      end
    end
  end
end
