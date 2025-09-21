#!/usr/bin/env ruby
# frozen_string_literal: true

require 'paru/filter'

Paru::Filter.run do
  with 'Emph' do |e|
    e.append(Paru::PandocFilter::Para.new([]))
  end
end
