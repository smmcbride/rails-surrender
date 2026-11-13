# frozen_string_literal: true

module Rails
  module Surrender
    class FieldMenu
      # A field a request may ask a model for: its kind (:attribute, :id_list or :expand), whether it renders by
      # default, and, for an expand, the field menu of the model it leads to.
      Field = Data.define(:name, :kind, :default, :menu) do
        def default?
          default
        end
      end
    end
  end
end
