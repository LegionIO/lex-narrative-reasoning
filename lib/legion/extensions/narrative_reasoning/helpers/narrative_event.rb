# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module NarrativeReasoning
      module Helpers
        class NarrativeEvent
          attr_reader :id, :content, :event_type, :characters, :causes, :timestamp, :domain

          def initialize(content:, event_type:, characters: [], causes: [], domain: nil, id: nil, timestamp: nil)
            @id         = id || SecureRandom.uuid
            @content    = content
            @event_type = event_type
            @characters = Array(characters).dup
            @causes     = Array(causes).dup
            @domain     = domain
            @timestamp  = timestamp || Time.now.utc
          end

          def to_h
            {
              id:         @id,
              content:    @content,
              event_type: @event_type,
              characters: @characters,
              causes:     @causes,
              domain:     @domain,
              timestamp:  @timestamp
            }
          end
        end
      end
    end
  end
end
