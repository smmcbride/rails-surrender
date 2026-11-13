# frozen_string_literal: true

module Rails
  module Surrender
    class Menu
      # A filter a request may name, and the column it compares, or nil for a filter the model defines under a name of
      # its own.
      Filter = Data.define(:name, :column)
    end
  end
end
