# frozen_string_literal: true

require 'legion/extensions/narrative_reasoning/helpers/narrative_event'
require 'legion/extensions/narrative_reasoning/helpers/narrative'
require 'legion/extensions/narrative_reasoning/helpers/narrative_engine'
require 'legion/extensions/narrative_reasoning/runners/narrative_reasoning'

module Legion
  module Extensions
    module NarrativeReasoning
      class Client
        include Runners::NarrativeReasoning

        def initialize(**)
          @narrative_engine = Helpers::NarrativeEngine.new
        end

        private

        attr_reader :narrative_engine
      end
    end
  end
end
