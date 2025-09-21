#!/usr/bin/env ruby

require 'paru/filter'

def printBlock(block, indent = 0)
  puts "#{'    ' * indent}#{block}"
  return unless block.has_children?

  block.each do |child|
    printBlock child, indent + 1
  end
end

filter = Paru::Filter.new

filter.run do |doc|
  doc
end
