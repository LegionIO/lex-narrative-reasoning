# frozen_string_literal: true

require 'legion/extensions/narrative_reasoning/version'
require 'legion/extensions/narrative_reasoning/helpers/narrative_event'
require 'legion/extensions/narrative_reasoning/helpers/narrative'
require 'legion/extensions/narrative_reasoning/helpers/narrative_engine'
require 'legion/extensions/narrative_reasoning/runners/narrative_reasoning'

module Legion
  module Extensions
    module NarrativeReasoning
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
