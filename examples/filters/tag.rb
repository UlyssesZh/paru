#!/usr/bin/env ruby
# Tags all inline nodes with 'TAG:(...)'
require 'paru/filter'

Paru::Filter.run do
  with '*' do |node|
    node.inner_markdown = "TAG:(#{node.inner_markdown})" if node.is_inline?
  end
end
