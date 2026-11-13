# frozen_string_literal: true

RSpec.describe Rails::Surrender::Menu do
  def outline(menu)
    menu.fields.map do |field|
      entry = [field.name, field.kind, field.default?]
      field.menu ? entry + [outline(field.menu)] : entry
    end
  end

  describe '#fields' do
    it 'lists default then available fields, in render order, with the menu below each expand' do
      expect(outline(Author.surrender_menu)).to eq(
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
      book_fields = Book.surrender_menu.fields.map(&:name)

      expect(book_fields).not_to include(:prequel)
      expect(book_fields).to include(:author)
    end

    it 'rejects a polymorphic expand' do
      expect { Review.surrender_menu.fields }.to raise_error(ArgumentError, /polymorphic.*reviewable/)
    end
  end

  describe '#filters' do
    let(:filters) { Book.surrender_menu.filters.to_h { |filter| [filter.name, filter.column&.name] } }

    it 'lists an equality filter for each column, with the column it compares' do
      expect(filters).to include('title' => 'title', 'author_id' => 'author_id')
    end

    it 'lists before and after filters for each time, named without _at' do
      expect(filters).to include('created_before' => 'created_at', 'published_after' => 'published_at')
    end

    it 'lists the filters the model defines, without a column' do
      expect(filters).to include('long' => nil)
    end

    it 'keeps the column of a generated filter the model replaces' do
      expect(filters).to include('genre' => 'genre')
    end

    it 'lists no filter twice' do
      names = Book.surrender_menu.filters.map(&:name)

      expect(names).to eq(names.uniq)
    end
  end

  describe '#page_size' do
    it 'is the page size the app configures' do
      expect(Book.surrender_menu.page_size).to eq(Rails::Surrender.page_size)
    end
  end

  describe '#sorts' do
    let(:sorts) { Book.surrender_menu.sorts }

    it 'lists the columns, then the columns of singular associations, then the sorts the model defines' do
      expect(sorts.first(3)).to eq(%w[id author_id prequel_id])
      expect(sorts).to include('author.name', 'prequel.title')
      expect(sorts.last).to eq('title_length')
    end

    it 'lists a sort the model defines under a column name once' do
      expect(sorts.count('genre')).to eq(1)
    end

    it 'leaves out the columns of associations that hold many records' do
      expect(sorts.grep(/\Achapters\./)).to be_empty
      expect(Author.surrender_menu.sorts.grep(/\Abooks\./)).to be_empty
    end
  end
end
