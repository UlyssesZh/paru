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
#++
require 'yaml'
require_relative '../pandoc'
require_relative '../filter_error'

module Paru
  module PandocFilter
    # A Metadata object is a Ruby Hash representation of a pandoc metadata
    # node.
    class Metadata < Hash
      # Create a new Metadata object based on the contents.
      #
      # @param contents [MetaMap|String|Hash] the initial contents of this
      #   metadata. If contents is a String, it is treated as a YAML string
      #   and converted to a Hash first.
      # @param treat_metadata_strings_as_plain_strings [Boolean = false] treat
      # metadata string values as plain strings instead of markdown strings if
      # all AST leaf metadata string values have pandoc type "MetaString". This
      # option is only relevant when you **only** set metadata string values via
      # command-line option `--metadata` and not also via a YAML or title block.
      # Using this option improves performance in this specific situation
      # because metadata values don't have to be converted to string by pandoc
      # in a separate process but can be collected as is.
      #
      # @raise Error when converting contents to a Hash fails
      def initialize(contents = {}, treat_metadata_strings_as_plain_strings: false)
        # When feature toggle treat_metadata_strings_as_plain_strings is on,
        # try to map the MetaMap node to a Hash directly and use that as the
        # contents of this Metadata object. We can only map the MetaMap node
        # when all string values have pandoc type "MetaString".
        if treat_metadata_strings_as_plain_strings && contents.is_a?(PandocFilter::MetaMap)
          metadata_hash = meta_to_value(contents)
          contents = metadata_hash unless metadata_hash.nil?
        end

        contents = convert_to_hash_via_yaml(contents) unless contents.is_a?(Hash)

        # Merge the contents with this newly created Metadata
        super()

        contents.each do |key, value|
          self[key] = value
        end
      end

      # Convert this Metadata to a pandoc AST representation of
      # metadata: {PandocFilter::Meta}
      #
      # @return [Meta] the pandoc AST representation as a {PandocFilter::Meta} node
      def to_meta
        if empty?
          PandocFilter::Meta.new({})
        else
          begin
            yaml_string = "#{clean_hash.to_yaml}..."
            yaml2json = Paru::Pandoc.new do
              from 'markdown'
              to 'json'
            end
            json_string = yaml2json << yaml_string
            meta_doc = PandocFilter::Document.from_JSON json_string
            meta_doc.meta
          rescue StandardError
            # Ignore silently to not interfere with pandoc conversion
          end
        end
      end

      private

      # Convert a {PandocFilter::Meta} node to a Metadata
      #
      # @param meta [Meta|MetaMap] the {PandocFilter::Meta} node to convert to a
      #   MetadataHash
      def meta2yaml(meta)
        json2yaml = Paru::Pandoc.new do
          from 'json'
          to 'markdown'
          standalone
        end
        meta = PandocFilter::Meta.from_meta_map(meta) unless meta.is_a? PandocFilter::Meta
        meta_doc = PandocFilter::Document.new(PandocFilter::CURRENT_PANDOC_VERSION, meta.to_ast, [])
        yaml_string = json2yaml << meta_doc.to_JSON
        yaml_string.strip
      rescue StandardError
        # Ignore silently to not interfere with pandoc conversion
      end

      # Create a true Hash from this Metadata to prevent the +to_yaml+
      # method from mixing in the name of this class and confusing pandoc
      def clean_hash
        hash = {}
        each do |key, value|
          hash[key] = value
        end
        hash
      end

      def convert_to_hash_via_yaml(contents)
        # If not a Hash, it is either a YAML string or can be
        # converted to a YAML string
        if contents.is_a? PandocFilter::MetaMap
          yaml_string = meta2yaml contents
        elsif contents.is_a? String
          yaml_string = contents
        else
          raise FilterError, "Expected a Hash, MetaMap, or String, got '#{contents}' instead."
        end

        # Try to convert the YAML string to a Hash
        contents = if yaml_string.empty?
                     {}
                   else
                     YAML.safe_load yaml_string, permitted_classes: [Date]
                   end

        unless contents
          # Error parsing YAML
          raise FilterError, "Unable to convert YAML string '#{yaml_string}' to a Hash."
        end

        contents
      end

      def meta_to_value(value)
        case value
        when MetaBlocks, MetaInlines
          # MetaBlocks and MetaInlines represent pandoc formatted markdown
          # nodes. Needs to be converted by pandoc.
          nil
        when MetaValue
          value.value.to_s
        when MetaList
          value.map do |m|
            mapped = meta_to_value(m)

            return nil if mapped.nil?

            mapped
          end
        when MetaMap
          mapped_map = {}

          value.each do |k, m|
            mapped = meta_to_value(m)

            return nil if mapped.nil?

            mapped_map[k] = mapped
          end

          mapped_map
        end
      end
    end
  end
end
