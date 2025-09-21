# frozen_string_literal: true

#--
# Copyright 2015--2025 Huub de Beer <Huub@heerdebeer.org>
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
#--
require_relative 'inline'

module Paru
  module PandocFilter
    # A Citation consists of an id, a prefix, a suffix, a mode, a note
    # number, and integer hash. All of which are optional.
    #
    # @see https://hackage.haskell.org/package/pandoc-types-1.17.0.5/docs/Text-Pandoc-Definition.html#t:Citation
    #
    # @!attribute id
    #   @return [String]
    #
    # @!attribute prefix
    #   @return [Array<Inline>]
    #
    # @!attribute suffix
    #   @return [Array<Inline>]
    #
    # @!attribute mode
    #   @return [String]
    #
    # @!attribute note_num
    #   @return [Integer]
    #
    # @!attribute hash
    #   @return [Integer]
    class Citation
      attr_accessor :id, :prefix, :suffix, :mode, :note_num, :hash

      # Create a new Citation node base on an AST specification
      #
      # @param spec [Hash] the specification of this citation
      def initialize(spec)
        @id = spec['citationId'] if spec.key? 'citationId'
        @prefix = Inline.new spec['citationPrefix'] if spec.key? 'citationPrefix'
        @suffix = Inline.new spec['citationSuffix'] if spec.key? 'citationSuffix'
        @mode = spec['citationMode'] if spec.key? 'citationMode'
        @note_num = spec['citationNoteNum'] if spec.key? 'citationNoteNum'
        @hash = spec['citationHash'] if spec.key? 'citationHash'
      end

      # Convert this Citation to an AST representation
      def to_ast
        citation = {}
        citation['citationId'] = @id unless @id.nil?
        citation['citationPrefix'] = @prefix.ast_contents unless @prefix.nil?
        citation['citationSuffix'] = @suffix.ast_contents unless @suffix.nil?
        citation['citationMode'] = @mode unless @mode.nil?
        citation['citationNoteNum'] = @note_num unless @note_num.nil?
        citation['citationHash'] = @hash unless @hash.nil?
        citation
      end
    end
  end
end
