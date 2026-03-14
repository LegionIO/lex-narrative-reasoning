# frozen_string_literal: true

require_relative 'lib/legion/extensions/narrative_reasoning/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-narrative-reasoning'
  spec.version       = Legion::Extensions::NarrativeReasoning::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Narrative Reasoning'
  spec.description   = 'Narrative reasoning engine for brain-modeled agentic AI — story structure, causal chains, arc progression'
  spec.homepage      = 'https://github.com/LegionIO/lex-narrative-reasoning'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-narrative-reasoning'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-narrative-reasoning'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-narrative-reasoning'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-narrative-reasoning/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-narrative-reasoning.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
