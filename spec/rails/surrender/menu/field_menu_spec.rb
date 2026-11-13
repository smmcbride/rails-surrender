# frozen_string_literal: true

RSpec.describe Rails::Surrender::FieldMenu do
  def outline(menu)
    menu.fields.map do |field|
      entry = [field.name, field.kind, field.default?]
      field.menu ? entry + [outline(field.menu)] : entry
    end
  end

  describe '#fields' do
    it 'lists default then available fields, in render order, with the menu below each expand' do
      expect(outline(described_class.new(Author))).to eq(
        [[:id, :attribute, true], [:name, :attribute, true], [:created_at, :attribute, false],
         [:book_ids, :id_list, false],
         [:books, :expand, false,
          [[:id, :attribute, true], [:title, :attribute, true], [:genre, :attribute, true],
           [:pages, :attribute, false], [:published_at, :attribute, false], [:created_at, :attribute, false],
           [:chapter_ids, :id_list, false],
           [:chapters, :expand, false, [[:id, :attribute, true], [:title, :attribute, true],
                                        [:position, :attribute, true]]]]]]
      )
    end

    it 'leaves out expands back into a model above, recognising STI subclasses by their base class' do
      book_fields = described_class.new(Book).fields.map(&:name)

      expect(book_fields).not_to include(:prequel)
      expect(book_fields).to include(:author)
    end

    it 'rejects a polymorphic expand' do
      expect { described_class.new(Review).fields }.to raise_error(ArgumentError, /polymorphic.*reviewable/)
    end
  end
end
