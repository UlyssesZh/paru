#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/paru/filter'

Paru::Filter.run do
  with 'Image' do |image|
    caption = image.inner_markdown
    caption += " (width=#{image.attr['width']})" if image.attr.key? 'width'
    caption += " (height=#{image.attr['height']})" if image.attr.key? 'height'
    image.inner_markdown = caption
  end
end
