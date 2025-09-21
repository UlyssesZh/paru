# frozen_string_literal: true

#--
# Copyright 2020--2025 Huub de Beer <Huub@heerdebeer.org>
#
# This file is part of Paru
#
# Paru is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Paru is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Paru.  If not, see <http://www.gnu.org/licenses/>.
#++
require_relative 'block'
require_relative 'inner_markdown'
require_relative 'short_caption'

module Paru
  module PandocFilter
    # A table or figure's caption, can contain an optional short caption
    class Caption < Block
      include InnerMarkdown

      attr_accessor :short

      # Create a new Caption based on the contents
      #
      # @param contents [Array]
      def initialize(contents)
        @short = if contents[0].nil?
                   nil
                 else
                   ShortCaption.new contents[0]
                 end
        super(contents[1])
      end

      # Does this Caption have a short caption?
      #
      # @return [Boolean]
      def has_short?
        !@short.nil?
      end

      # Has this node a block?
      #
      # @return [Boolean] true
      def has_block?
        true
      end

      # The AST contents of this Caption node
      #
      # @return [Array]
      def ast_contents
        [
          has_short? ? @short.to_ast : nil,
          @children.map(&:to_ast)
        ]
      end

      # Create an AST representation of this Node
      #
      # @return [Hash]
      def to_ast
        ast_contents
      end
    end
  end
end
