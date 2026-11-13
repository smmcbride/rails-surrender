# frozen_string_literal: true

class Novel < Book
  surrenders :chapter_ids, :author
end
