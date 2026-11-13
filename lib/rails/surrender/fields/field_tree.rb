# frozen_string_literal: true

require_relative '../params/list_param'
require_relative 'node'

module Rails
  module Surrender
    # The fields one request renders, nested by expand, worked out from the model and the asks of the request and the
    # controller before any record loads. Preloading and rendering both read it, so they always agree.
    class FieldTree
      # `include:` and `exclude:` are the request's asks, as the query string gives them: `'books:[pages], author'`.
      # A controller's asks are lists: `[:pages, { author: [:name] }]`.
      def initialize(model, include: '', exclude: '', controller_include: [], controller_exclude: [])
        asks = Fields::Asks.new(request_include: Params::ListParam.parse(include, param: :include),
                                request_exclude: Params::ListParam.parse(exclude, param: :exclude),
                                controller_include: controller_include, controller_exclude: controller_exclude)
        @root = Fields::Node.new(model, asks, [model.base_class])
      end

      # Renders a record as a hash, or a relation as an array of them.
      def render(resource, ability:)
        records = resource.is_a?(ActiveRecord::Relation) ? resource.to_a : [resource]
        preload(records)
        rendered = records.map { |record| @root.for(record.class).render(record, ability) }
        resource.is_a?(ActiveRecord::Relation) ? rendered : rendered.first
      end

      def to_h
        @root.to_h
      end

      private

      # Level by level, each association loads once for every record that renders it, whatever the record's class.
      # STI subclasses then share a query for an association they inherit, and one only a subclass renders loads only
      # for that subclass's records, which a nested `includes` on the parent's relation can't name.
      def preload(records)
        level = { @root => records }
        until level.empty?
          variants = variants_in(level)
          load_associations(variants)
          level = level_below(variants)
        end
      end

      def variants_in(level)
        level.flat_map do |node, records|
          records.group_by(&:class).map { |klass, group| [node.for(klass), group] }
        end
      end

      def load_associations(variants)
        loading = Hash.new { |by_association, association| by_association[association] = [] }
        variants.each { |node, records| node.preloads.each { |association| loading[association].concat(records) } }
        loading.each do |association, records|
          ActiveRecord::Associations::Preloader.new(records: records, associations: association).call
        end
      end

      def level_below(variants)
        level = Hash.new { |records_by_node, node| records_by_node[node] = [] }
        variants.each do |node, records|
          node.branches.each do |name, branch|
            level[branch].concat(records.flat_map { |record| Array(record.public_send(name)) })
          end
        end
        level.transform_values { |records| records.compact.uniq }.reject { |_, records| records.empty? }
      end
    end
  end
end
