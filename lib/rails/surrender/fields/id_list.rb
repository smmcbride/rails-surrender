# frozen_string_literal: true

module Rails
  module Surrender
    module Fields
      # A field that names an association by its ids, such as chapter_ids, and renders them as a flat list.
      IdList = Data.define(:name, :association) do
        def rank
          2
        end

        def preload
          association
        end

        def circular?(_above)
          false
        end

        def branch(**); end

        def write(record, into:, **)
          into[name] = record.public_send(name)
        end

        def describe(_branch)
          :id_list
        end
      end
    end
  end
end
