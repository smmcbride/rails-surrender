# frozen_string_literal: true

module Rails
  module Surrender
    class FieldMenu
      # A field a request may ask a model for: the type of what it renders, whether it renders by default, and, for an
      # expand, the field menu of the model it leads to. An attribute's type is its Rails type, or nil for a method the
      # model defines; an id list is an :array, and an expand an :object or, for a collection, an :array.
      Field = Data.define(:name, :type, :default, :menu) do
        def default?
          default
        end

        def as_json(*)
          { name: name, type: type, default: default }.merge({ fields: menu }.compact).as_json
        end
      end
    end
  end
end
