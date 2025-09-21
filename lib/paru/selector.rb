# frozen_string_literal: false

#--
# Copyright 2015, 2016, 2017, 2022 Huub de Beer <Huub@heerdebeer.org>
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
require_relative 'error'

module Paru
  # SelectorParseError is thrown when there is an error parsing a selector
  # used in a filter.
  class SelectorParseError < Error
  end

  # A Selector models a relationship between Pandoc AST nodes, such as
  # parent-child or sibling. Selectors in paru are like CSS selectors, but
  # more limited because the Pandoc AST is quite simple.
  #
  # Given a selector expression, Selector determines if a node complies with
  # that selector expression or not.
  class Selector
    # Pseudo selector to select any inline and block node
    ANY_SELECTOR = '*'.freeze

    # All pseudo selectors
    PSEUDO_SELECTORS = [ANY_SELECTOR].freeze

    # Create a new Selector based on the selector string
    #
    # @param selector [String] the selector string
    def initialize(selector)
      @type = 'Unknown'
      @relations = []
      parse selector
    end

    # Does node get selected by this Selector in the context of the already filtered
    # nodes?
    #
    # @param node [Node] the node to check against this Selector
    # @param filtered_nodes [Array<Node>] the context of filtered nodes to take
    #   into account as well
    #
    # @return [Boolean] True if the node in the context of the
    #   filtered_nodes is selected by this Selector
    def matches?(node, filtered_nodes)
      case @type
      when ANY_SELECTOR
        Paru::PANDOC_TYPES.include? node.type
      else
        node.type == @type and
          @classes.all? { |c| node.has_class? c } and
          @relations.all? { |r| r.matches? node, filtered_nodes }
      end
    end

    private

    S = /\s*/.freeze
    # Improved CSS class selector taken from https://stackoverflow.com/questions/448981/which-characters-are-valid-in-css-class-names-selectors/449000#449000
    CLASS = /(\.-?[_a-zA-Z]+[_a-zA-Z0-9-]*)/.freeze
    TYPE = /(?<type>(?<name>[A-Z][a-zA-Z]*|\*)(?<classes>#{CLASS}*))/.freeze
    OTHER_TYPE = /(?<other_type>(?<other_name>[A-Z][a-zA-Z]*)(?<other_classes>#{CLASS}*))/.freeze
    OPERATOR = /(?<operator>\+|-|>)/.freeze
    DISTANCE = /(?<distance>[1-9][0-9]*)/.freeze
    RELATION = /(?<relation>#{S}#{OTHER_TYPE}#{S}#{OPERATOR}#{S}#{DISTANCE}?#{S})/.freeze
    RELATIONS = /(?<relations>#{RELATION}+)/.freeze
    SELECTOR = /\A#{S}(?<selector>#{RELATIONS}?#{S}#{TYPE})#{S}\Z/.freeze

    # Parse the selector_string to construct this Selector
    def parse(selector_string)
      partial_match = expect_match SELECTOR, selector_string
      @type, @classes = expect_pandoc_type partial_match

      while continue_parsing? partial_match
        operator = expect partial_match, :operator
        distance = expect_integer partial_match, :distance
        type, classes = expect_pandoc_other_type partial_match

        @relations.push Relation.new(operator, distance, type, classes)

        partial_match = rest partial_match
      end
    end

    # Is type actually a Pandoc AST node type?
    def is_pandoc_type(type)
      Paru::PANDOC_TYPES.concat(PSEUDO_SELECTORS).include? type
    end

    alias pandoc_type? is_pandoc_type

    def expect(parts, part)
      raise SelectorParseError, "Expected #{part}" if parts[part].nil?

      parts[part]
    end

    def expect_match(regexp, string)
      match = regexp.match string
      raise SelectorParseError, "Unable to parse '#{string}'" if match.nil?

      match
    end

    def expect_pandoc_type(parts)
      type = expect parts, :name
      classes = parts[:classes].split('.').reject(&:empty?) unless parts[:classes].nil?
      raise SelectorParseError, "Expected a Pandoc type, got '#{type}' instead" unless is_pandoc_type type

      [type, classes]
    end

    def expect_pandoc_other_type(parts)
      type = expect parts, :other_name
      classes = parts[:other_classes].split('.').reject(&:empty?) unless parts[:other_classes].nil?
      raise SelectorParseError, "Expected a Pandoc type, got '#{type}' instead" unless is_pandoc_type type

      [type, classes]
    end

    def expect_integer(parts, part)
      if parts[part].nil?
        number = 0
      else
        number = parts[part].to_i
        raise SelectorParseError, "Expected a positive #{part}, got '#{parts[part]}' instead" if number <= 0
      end
      number
    end

    def continue_parsing?(parts)
      !parts.nil? and !parts[:relations].nil?
    end

    def rest(parts)
      rest_string = parts[:relations].slice 0, parts[:relations].size - parts[:relation].size
      RELATIONS.match rest_string
    end
  end

  # @private
  class Relation
    def initialize(selector, distance, type, classes)
      @selector = selector
      @distance = distance
      @type = type
      @classes = classes
    end

    def matches?(node, filtered_nodes)
      level_nodes = filtered_nodes.keep_if do |n|
        node.is_inline? == n.is_inline? or
          node.can_act_as_both_block_and_inline?
      end
      previous_nodes = previous level_nodes, @distance
      case @selector
      when '+'
        in_sequence? node, previous_nodes
      when '-'
        not_in_sequence? node, previous_nodes
      when '>'
        is_descendant? node
      else
        false
      end
    end

    def in_sequence?(_node, previous_nodes)
      previous_nodes.any? do |other|
        other.type == @type and @classes.all? { |c| other.has_class? c }
      end
    end

    def not_in_sequence?(_node, previous_nodes)
      previous_nodes.all? do |other|
        other.type != @type or !@classes.all? { |c| other.has_class? c }
      end
    end

    def is_descendant?(node)
      distance = 0
      parent = nil
      begin
        distance += 1 if @distance.positive?
        node = parent unless parent.nil?
        parent = node.parent
        ancestry = parent.type == @type and @classes.all? { |c| parent.has_class? c }
      end while !ancestry && !parent.is_root? && distance <= @distance
      ancestry
    end

    alias descendant? is_descendant?

    def previous(filtered_nodes, distance)
      distance = [distance, filtered_nodes.size - 1].min
      if distance <= 0
        filtered_nodes.slice(0, filtered_nodes.size - 1)
      else
        filtered_nodes.slice((-1 * distance) - 1, distance)
      end
    end
  end
end
