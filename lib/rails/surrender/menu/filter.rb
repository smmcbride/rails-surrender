# frozen_string_literal: true

module Rails
  module Surrender
    class SelectionMenu
      # A filter a request may name, and the column it compares, or nil for a filter the model defines under a name of
      # its own.
      Filter = Data.define(:name, :column) do
        # The column's Rails type tells a client what value to send, such as an ISO 8601 time for a datetime.
        def as_json(*)
          { type: column&.type }.as_json
        end
      end
    end
  end
end
