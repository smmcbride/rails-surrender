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

  describe 'with a controller’s asks' do
    def defaults(menu)
      menu.fields.to_h { |field| [field.name, field.default?] }
    end

    def asks(**lists)
      Rails::Surrender::Fields::Asks.new(**lists)
    end

    it 'makes a field the controller includes a default, even one the model doesn’t offer' do
      menu = described_class.new(Author, asks: asks(controller_include: [:updated_at]))

      expect(defaults(menu)).to include(updated_at: true)
    end

    it 'keeps a default the controller excludes as available, as a request may still include it' do
      menu = described_class.new(Author, asks: asks(controller_exclude: [:name]))

      expect(defaults(menu)).to include(name: false)
    end

    it 'leaves out a field the controller both includes and excludes, when the model doesn’t offer it' do
      menu = described_class.new(Author, asks: asks(controller_include: [:updated_at],
                                                    controller_exclude: [:updated_at]))

      expect(defaults(menu)).not_to have_key(:updated_at)
    end

    it 'passes nested asks to the menu of each expand' do
      menu = described_class.new(Author, asks: asks(controller_exclude: [{ books: [:genre] }]))
      books = menu.fields.find { |field| field.name == :books }

      expect(defaults(menu)).to include(books: false)
      expect(defaults(books.menu)).to include(genre: false, title: true)
    end
  end

  describe '#as_json' do
    it 'lists each field’s name, kind and default, nesting the fields of an expand' do
      json = described_class.new(Chapter).as_json

      expect(json.last).to eq('name' => 'book', 'kind' => 'expand', 'default' => true,
                              'fields' => described_class.new(Book, above: [Chapter, Book]).as_json)
      expect(json.first).to eq('name' => 'id', 'kind' => 'attribute', 'default' => true)
    end
  end
end
