# frozen_string_literal: true

module Rails
  module Surrender
    module Fields
      # What a request and a controller ask one level of the tree to include and exclude. Each list holds bare names,
      # and hashes that carry the asks for the level below, such as { 'author' => ['name'] }.
      Asks = Data.define(:request_include, :request_exclude, :controller_include, :controller_exclude) do
        def initialize(request_include: [], request_exclude: [], controller_include: [], controller_exclude: [])
          super(request_include: listed(request_include), request_exclude: listed(request_exclude),
                controller_include: listed(controller_include), controller_exclude: listed(controller_exclude))
        end

        def request_includes
          names_in(request_include)
        end

        def controller_includes
          names_in(controller_include)
        end

        # A request's include wins over any exclude. `author:[name]` excludes the author's name, not the author, so
        # only bare names exclude at this level.
        def excludes?(name)
          return false if request_includes.include?(name)

          (request_exclude + controller_exclude).grep_v(Hash).map(&:to_sym).include?(name)
        end

        def below(name)
          self.class.new(**to_h.transform_values { |list| asks_below(list)[name] })
        end

        private

        def listed(list)
          (list.is_a?(Array) ? list : [list]).compact
        end

        def names_in(list)
          list.flat_map { |item| item.is_a?(Hash) ? item.keys : item }.map(&:to_sym).uniq
        end

        def asks_below(list)
          list.grep(Hash).reduce({}, :merge).transform_keys(&:to_sym)
        end
      end
    end
  end
end
