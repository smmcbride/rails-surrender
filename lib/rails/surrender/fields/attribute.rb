# frozen_string_literal: true

module Rails
  module Surrender
    module Fields
      # A field rendered as the value its record returns for it.
      Attribute = Data.define(:name, :model) do
        # Every record leads with its id, wherever the model or the asks list it.
        def rank
          name == :id ? 0 : 1
        end

        # The Rails type of the attribute, such as :string or :datetime, or nil for a method the model defines.
        def type
          model.type_for_attribute(name).type
        end

        def preload; end

        def circular?(_above)
          false
        end

        def branch(**); end

        def menu(**); end

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
