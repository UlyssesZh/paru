#!/usr/bin/env ruby
# frozen_string_literal: true

require 'paru/filter'

Paru::Filter.run do
  stop!
  warn 'Do not show this warning!'
end
