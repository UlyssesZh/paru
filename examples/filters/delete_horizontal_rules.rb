#!/usr/bin/env ruby
require 'paru/filter'

Paru::Filter.run do
  with 'HorizontalRule' do |rule|
    rule.parent.delete rule if rule.has_parent?
  end
end
