#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/paru/filter'

Paru::Filter.run do
  with 'Image' do |image|
    image.inner_markdown = "Figure. #{image.inner_markdown}"
  end
end
