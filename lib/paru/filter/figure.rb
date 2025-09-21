# frozen_string_literal: true

#--
# Copyright 2023 Huub de Beer <Huub@heerdebeer.org>
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
require_relative 'attr'
require_relative 'caption'
require_relative 'inner_markdown'

module Paru
  module PandocFilter
    # A Figure node consisting of an attribute object, a caption, and a list of Block nodes.
    class Figure < Block
      include InnerMarkdown

      # A Figure node has an attribute object
      #
      # @!attribute attr
      #   @return [Attr]
      #
      # @!attribute caption
      #   @return Caption
      attr_accessor :attr, :caption

      # Create a new Figure node based on the contents
      #
      # @param contents [Array]
      def initialize(contents)
        @attr = Attr.new contents[0]
        @caption = Caption.new contents[1]
        super(contents[2])
      end

      # Create an AST representation of this Figure node.
      def ast_contents
        [
          @attr.to_ast,
          @caption.to_ast,
          super
        ]
      end

      # Has this Figure node Blocks as children?
      #
      # @return [Boolean] true
      def has_block?
        true
      end
    end
  end
end
