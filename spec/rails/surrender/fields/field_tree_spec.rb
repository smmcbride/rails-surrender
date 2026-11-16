# frozen_string_literal: true

RSpec.describe Rails::Surrender::FieldTree do
  let(:ability) { Rails::Surrender::DefaultAbility.new }

  describe '#to_h' do
    it 'holds the default fields of a model' do
      expect(described_class.new(Book).to_h).to eq(id: :attribute, title: :attribute, genre: :attribute)
    end

    it 'rejects a malformed request ask, naming it' do
      expect { described_class.new(Book, exclude: 'author:[') }
        .to raise_error(Rails::Surrender::Error, 'The exclude parameter was improperly formatted.')
    end

    it 'adds the fields a request includes, nested by expand' do
      tree = described_class.new(Author, include: 'book_ids, books:[pages]')

      expect(tree.to_h).to eq(id: :attribute, name: :attribute, book_ids: :id_list,
                              books: { id: :attribute, title: :attribute, genre: :attribute, pages: :attribute })
    end

    it 'adds the fields a controller includes, without checking that they are available' do
      expect(described_class.new(Book, controller_include: [:updated_at]).to_h).to include(updated_at: :attribute)
    end

    it 'removes the fields a request or controller excludes' do
      tree = described_class.new(Book, exclude: 'genre', controller_exclude: [:title])

      expect(tree.to_h).to eq(id: :attribute)
    end

    it 'keeps a field the request includes even when it is excluded' do
      tree = described_class.new(Book, include: 'genre', controller_exclude: [:genre])

      expect(tree.to_h).to include(genre: :attribute)
    end

    it 'applies a nested exclude to the next level only' do
      tree = described_class.new(Chapter, exclude: 'book:[genre]')

      expect(tree.to_h).to eq(id: :attribute, title: :attribute, position: :attribute,
                              book: { id: :attribute, title: :attribute })
    end

    it 'leaves out expands back into a model already above, recognising STI subclasses by their base class' do
      tree = described_class.new(Author, include: 'books:[author, chapters, prequel]')

      expect(tree.to_h[:books]).to eq(id: :attribute, title: :attribute, genre: :attribute,
                                      chapters: { id: :attribute, title: :attribute, position: :attribute })
    end

    it 'orders id first, then attributes, id lists and expands' do
      model = stub_const('Leaf', Class.new(ApplicationRecord) do
        self.table_name = 'chapters'
        belongs_to :book
        surrenders :book, :title, :id
      end)
      tree = described_class.new(model, controller_include: %i[book_id position])

      expect(tree.to_h.keys).to eq(%i[id title book_id position book])
    end

    it 'orders fields by default, then controller, then request within each kind' do
      tree = described_class.new(Author, include: 'created_at, book_ids', controller_include: %i[updated_at])

      expect(tree.to_h.keys).to eq(%i[id name updated_at created_at book_ids])
    end
  end

  describe 'validation' do
    it 'rejects a field the model does not make available' do
      expect { described_class.new(Author, include: 'updated_at') }
        .to raise_error(Rails::Surrender::Error, '[:updated_at] is not a valid include parameter.')
    end

    it 'rejects a name that is not a field' do
      expect { described_class.new(Author, include: 'nonsense') }
        .to raise_error(Rails::Surrender::Error, '[:nonsense] is not a valid include parameter.')
    end

    it 'rejects an unavailable field below the top level before any query runs' do
      queries = capture_queries do
        expect { described_class.new(Author, include: 'books:[updated_at]') }
          .to raise_error(Rails::Surrender::Error, '[:updated_at] is not a valid include parameter.')
      end

      expect(queries).to be_empty
    end

    it 'rejects a polymorphic expand' do
      expect { described_class.new(Review) }.to raise_error(ArgumentError, /polymorphic.*reviewable/)
    end
  end

  describe '#render' do
    include_context 'with a library'

    it 'renders a record as a hash' do
      rendered = described_class.new(Author).render(tolkien, ability: ability)

      expect(rendered).to eq(id: tolkien.id, name: 'Tolkien')
    end

    it 'renders a relation as an array' do
      rendered = described_class.new(Author).render(Author.order(:id), ability: ability)

      expect(rendered).to eq([{ id: tolkien.id, name: 'Tolkien' }, { id: le_guin.id, name: 'Le Guin' }])
    end

    it 'renders each STI record in a collection with its own class’s fields' do
      rendered = described_class.new(Book).render(Book.order(:id), ability: ability).index_by { |book| book[:id] }

      expect(rendered[hobbit.id]).to eq(id: hobbit.id, title: 'The Hobbit', genre: 'fantasy',
                                        chapter_ids: [unexpected_party.id, roast_mutton.id],
                                        author: { id: tolkien.id, name: 'Tolkien' })
      expect(rendered[essays.id]).to eq(id: essays.id, title: 'Dancing at the Edge', genre: 'essays')
    end

    it 'renders a missing association as nil' do
      orphan = Chapter.new(title: 'Lost', position: 1).tap { |chapter| chapter.save!(validate: false) }

      expect(described_class.new(Chapter).render(orphan, ability: ability)).to include(book: nil)
    end

    it 'leaves out records in a nested collection the ability cannot read' do
      Chapter.create!(book: hobbit, title: 'Secret', position: 3)

      rendered = described_class.new(Book, include: 'chapters')
                                .render(hobbit, ability: ChaptersController::Ability.new('Secret'))

      expect(rendered[:chapters].pluck(:title)).to contain_exactly('An Unexpected Party', 'Roast Mutton')
    end

    it 'renders a nested record the ability cannot read as nil' do
      cannot_read_books = Struct.new(:unused) { def can?(_action, subject) = !subject.is_a?(Book) }.new

      rendered = described_class.new(Chapter).render(unexpected_party, ability: cannot_read_books)

      expect(rendered).to include(book: nil)
    end

    it 'loads each association in one query across the classes that render it' do
      tree = described_class.new(Book, include: 'chapters')

      queries = capture_queries { tree.render(Book.all, ability: ability) }

      expect(queries.grep(/FROM "chapters"/).size).to eq(1)
      expect(queries.grep(/FROM "authors"/).size).to eq(1)
    end

    it 'does not load an association only a subclass renders when no record is of that subclass' do
      queries = capture_queries { described_class.new(Book).render(Book.where(type: nil), ability: ability) }

      expect(queries.grep(/FROM "authors"|FROM "chapters"/)).to be_empty
    end

    it 'runs the same number of queries however many records it renders' do
      tree = described_class.new(Author, include: 'books:[chapters, chapter_ids]')
      baseline = count_queries { tree.render(Author.all, ability: ability) }

      2.times { |n| Novel.create!(author: Author.create!(name: "A#{n}"), title: "B#{n}").chapters.create!(title: 'C') }

      expect(count_queries { tree.render(Author.all, ability: ability) }).to eq(baseline)
    end
  end
end
