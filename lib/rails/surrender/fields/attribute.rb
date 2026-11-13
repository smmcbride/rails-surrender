# frozen_string_literal: true

module Rails
  module Surrender
    module Fields
      # A field rendered as the value its record returns for it.
      Attribute = Data.define(:name) do
        # Every record leads with its id, wherever the model or the asks list it.
        def rank
          name == :id ? 0 : 1
        end

        def preload; end

        def circular?(_above)
          false
        end

        def branch(**); end

        def write(record, into:, **)
          into[name] = record.public_send(name)
        end

        def describe(_branch)
          :attribute
        end
      end
    end
  end
end
