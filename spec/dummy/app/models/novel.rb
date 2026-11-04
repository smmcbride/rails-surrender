# frozen_string_literal: true

class Novel < Book
  surrenders attributes: [:chapter_ids],
             expands: [:author]
end
