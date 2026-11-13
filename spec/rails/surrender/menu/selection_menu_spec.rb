# frozen_string_literal: true

RSpec.describe Rails::Surrender::SelectionMenu do
  describe '#filters' do
    let(:filters) { described_class.new(Book).filters.to_h { |filter| [filter.name, filter.column&.name] } }

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
      names = described_class.new(Book).filters.map(&:name)

      expect(names).to eq(names.uniq)
    end
  end

  describe '#page_size' do
    it 'is the page size the app configures' do
      expect(described_class.new(Book).page_size).to eq(Rails::Surrender.page_size)
    end
  end

  describe '#sorts' do
    let(:sorts) { described_class.new(Book).sorts }

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
      expect(described_class.new(Author).sorts.grep(/\Abooks\./)).to be_empty
    end
  end
end
