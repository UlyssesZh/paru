# frozen_string_literal: true

#--
# Copyright 2015, 2016, 2017, 2020, 2023 Huub de Beer <Huub@heerdebeer.org>
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
require_relative '../pandoc'
require_relative 'ast_manipulation'

module Paru
  # PandocFilter is a module containig the paru's Filter functionality
  module PandocFilter
    # A Paru::Pandoc converter from JSON to markdown
    AST2MARKDOWN = Paru::Pandoc.new do
      from 'json'
      to 'markdown-smart'
      preserve_tabs true
    end

    # A Paru::Pandoc converter from markdown to JSON
    MARKDOWN2JSON = Paru::Pandoc.new do
      from 'markdown+smart'
      to 'json'
      preserve_tabs true
    end

    # Every node in a Pandoc AST is mapped to Node. Filters are all about
    # manipulating Nodes.
    #
    # @!attribute parent
    #   @return [Node] the parent node, if any.
    class Node
      include Enumerable
      include ASTManipulation

      attr_accessor :parent

      # Block level nodes
      require_relative 'block_quote'
      require_relative 'block'
      require_relative 'bullet_list'
      require_relative 'code_block'
      require_relative 'definition_list_item'
      require_relative 'definition_list'
      require_relative 'div'
      require_relative 'empty_block'
      require_relative 'header'
      require_relative 'horizontal_rule'
      require_relative 'line_block'
      require_relative 'null'
      require_relative 'ordered_list'
      require_relative 'para'
      require_relative 'plain'
      require_relative 'raw_block'
      require_relative 'table'
      require_relative 'caption'
      require_relative 'table_head'
      require_relative 'table_foot'
      require_relative 'row'
      require_relative 'cell'
      require_relative 'figure'

      # Inline level nodes
      require_relative 'cite'
      require_relative 'code'
      require_relative 'emph'
      require_relative 'empty_inline'
      require_relative 'image'
      require_relative 'inline'
      require_relative 'line_break'
      require_relative 'link'
      require_relative 'math'
      require_relative 'note'
      require_relative 'quoted'
      require_relative 'raw_inline'
      require_relative 'small_caps'
      require_relative 'soft_break'
      require_relative 'space'
      require_relative 'span'
      require_relative 'strikeout'
      require_relative 'strong'
      require_relative 'str'
      require_relative 'subscript'
      require_relative 'superscript'
      require_relative 'short_caption'
      require_relative 'underline'

      # Metadata level nodes
      require_relative 'meta_blocks'
      require_relative 'meta_bool'
      require_relative 'meta_inlines'
      require_relative 'meta_list'
      require_relative 'meta_map'
      require_relative 'meta_string'

      # Create a new Node with contents. Also indicate if this node has
      # inline children or block children.
      #
      # @param contents [Array<pandoc node in JSON> = []] the contents of
      #   this node
      # @param inline_children [Boolean] does this node have
      #   inline children (true) or block children (false).
      def initialize(contents = [], inline_children = false)
        @children = []
        @parent = nil

        return unless contents.is_a? Array

        contents.each do |elt|
          child = if PandocFilter.const_defined? elt['t']
                    PandocFilter.const_get(elt['t']).new elt['c']
                  elsif inline_children
                    PandocFilter::Inline.new elt['c']
                  else
                    PandocFilter::Plain.new elt['c']
                  end

          child.parent = self
          @children.push child
        end
      end

      # Create a new node from a markdown string. This is always a block
      # level node. If more
      # than one new node is created, a {Div} is created as a parent for
      # the newly created block nodes..
      #
      # @param markdown_string [String] the markdown string to convert
      #   to a AST node
      #
      # @return [Block|Div] The {Block} node created by converting
      #   markdown_string with pandoc; A {Div} node if this conversion
      #   holds more than one {Block} node.
      def self.from_markdown(markdown_string)
        node = Node.new []
        node.outer_markdown = markdown_string

        if node.children.size == 1
          node = node.children.first
        else
          container = from_markdown '<div></div>'
          container.children = node.children
          node = container
        end

        node
      end

      # For each child of this Node, yield the child
      #
      # @yield [Node]
      def each(&block)
        @children.each(&block)
      end

      # Does this node have any children?
      #
      # @return [Boolean] True if this node has any children, false
      #   otherwise.
      def has_children?
        defined? @children and !@children.nil? and @children.size.positive?
      end

      # Get this node's children,
      #
      # @return [Array<Node>] this node's children as an Array.
      def children
        if has_children?
          @children
        else
          []
        end
      end

      # Set this node's children
      #
      # @param list [Array<Node>] a list with nodes
      attr_writer :children

      # Does this node have a parent?
      #
      # @return [Boolean] True if this node has a parent, false
      #   otherwise.
      def has_parent?
        !@parent.nil?
      end

      # Is this a root node?
      #
      # @return [Boolean] True if this node has a no parent, false
      #   otherwise
      def is_root?
        !has_parent?
      end

      # Is this Node a Node or a leaf? See #is_leaf?
      #
      # @return [Boolean] A node is a node if it is not a leaf.
      def is_node?
        !is_leaf
      end

      # Is this Node a leaf? See also #is_node?
      #
      # @return [Boolean] A node is a leaf when it has no children
      #   false otherwise
      def is_leaf?
        !has_children?
      end

      # Does this node has a string value?
      #
      # @return [Boolean] true if this node has a string value, false
      #   otherwise
      def has_string?
        false
      end

      # Does this node have Inline contents?
      #
      # @return [Boolean] true if this node has Inline contents, false
      #   otherwise
      def has_inline?
        false
      end

      # Does this node have Block contents?
      #
      # @return [Boolean] true if this node has Block contents, false
      #   otherwise
      def has_block?
        false
      end

      # Is this node a Block level node?
      #
      # @return [Boolean] true if this node is a block level node, false
      #   otherwise
      def is_block?
        false
      end

      # Can this node act both as a block and inline node? Some nodes
      # are hybrids in this regard, like Math or Image
      #
      # @return [Boolean]
      def can_act_as_both_block_and_inline?
        false
      end

      # Is this an Inline level node?
      #
      # @return [Boolean] true if this node is an inline level node,
      #   false otherwise
      def is_inline?
        false
      end

      # Convert this Node to a metadata value. If this Node
      # {is_inline?}, it is converted to {MetaInlines} if it is
      # {is_block?}, it is converted to {MetaBlocks}.
      #
      # @return [MetaInlines|MetaBlocks]
      def toMetadata
        if is_inline?
          MetaInlines.new to_ast, true
        elsif is_blocks?
          MetaBlocks.new to_ast, false
        else
          # ?
        end
      end

      # If this node has attributes with classes, is name among them?
      #
      # @param name [String] the class name to search for
      #
      # @return [Boolean] true if this node has attributes with classes
      #   and name is among them, false otherwise
      def has_class?(name)
        if @attr.nil?
          false
        else
          @attr.has_class? name
        end
      end

      # A String representation of this Node
      #
      # @return [String]
      def to_s
        self.class.name
      end

      # The pandoc type of this Node
      #
      # @return [String]
      def type
        ast_type
      end

      # The AST type of this Node
      #
      # @return [String]
      def ast_type
        self.class.name.split('::').last
      end

      # An AST representation of the contents of this node
      #
      # @return [Array]
      def ast_contents
        if has_children?
          @children.map(&:to_ast)
        else
          []
        end
      end

      # Create an AST representation of this Node
      #
      # @return [Hash]
      def to_ast
        {
          't' => ast_type,
          'c' => ast_contents
        }
      end

      # Get the markdown representation of this Node, including the Node
      # itself.
      #
      # @return [String] the outer markdown representation of this Node
      def markdown
        temp_doc = PandocFilter::Document.fragment [self]
        AST2MARKDOWN << temp_doc.to_JSON
      end

      alias outer_markdown markdown

      # Set the markdown representation of this Node: replace this Node
      # by the Node represented by the markdown string. If an inline
      # node is being replaced and the replacement has more than one
      # paragraph, only the contents of the first paragraph is used
      #
      # @param markdown [String] the markdown string to replace this
      #   Node
      #
      # @example Replacing all horizontal lines by a Plain node saying "hi"
      #   Paru::Filter.run do
      #       with "HorizontalLine" do |line|
      #           line.markdown = "hi"
      #       end
      #   end
      #
      def markdown=(markdown)
        json = MARKDOWN2JSON << markdown
        temp_doc = PandocFilter::Document.from_JSON json

        if !has_parent? || is_root?
          @children = temp_doc.children
        else
          # replace current node by new nodes
          # There is a difference between inline and block nodes
          current_index = parent.find_index self

          # By default, pandoc creates a Block level node when
          # converting a string. However, if the original is a
          # inline level node, so should its replacement node(s) be.
          # Only using first block node (paragraph?)
          if is_inline?
            temp_doc = temp_doc.children.first

            unless temp_doc.children.all?(&:is_inline?)
              raise Error,
                    "Cannot replace the inline level node represented by '#{self.markdown}' with markdown that converts to block level nodes: '#{markdown}'."
            end
          else
            replacement = temp_doc.children.first
            @replacement = replacement unless replacement.nil? || (to_ast == replacement.to_ast)
          end

          index = current_index
          temp_doc.each do |child|
            index += 1
            parent.insert index, child
          end

          # Remove the original node
          parent.remove_at current_index
        end
      end

      alias outer_markdown= markdown=

      # Has this node been replaced by using the {markdown} method? If
      # so, return true.
      #
      # @return [Boolean]
      def has_been_replaced?
        !@replacement.nil?
      end

      # Get this node's replacemnt. Nil if it has not been replaced by
      # the {markdown} method
      #
      # @return [Node] This node's replacement or nil if there is none.
      def get_replacement
        @replacement
      end
    end
  end
end
