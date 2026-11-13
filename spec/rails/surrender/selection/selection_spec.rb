# frozen_string_literal: true

RSpec.describe Rails::Surrender::Selection do
  include_context 'with a library'

  def select_books(paginate: true, **params)
    described_class.new(params, paginate: paginate).apply(Book.all)
  end

  def titles(selected)
    selected.records.map(&:title)
  end

  describe 'resources that are not relations' do
    it 'passes them through untouched, without headers' do
      selection = described_class.new({ sort: 'title', filter: 'genre:essays', page: '2' })

      [hobbit, [1, 2], { status: 'ok' }, nil].each do |resource|
        selected = selection.apply(resource)

        expect([selected.records, selected.headers]).to eq([resource, {}])
      end
    end
  end

  describe 'filters' do
    it 'select records by the filter_by_ scopes of the model' do
      expect(titles(select_books(filter: 'genre:essays'))).to eq(['Dancing at the Edge'])
    end

    it 'select by an association through its foreign key' do
      expect(titles(select_books(filter: "author:#{tolkien.id}"))).to eq(['The Hobbit'])
    end

    it 'combine' do
      expect(titles(select_books(filter: "author:#{le_guin.id},genre:fantasy"))).to eq(['A Wizard of Earthsea'])
    end

    it 'reject a name the model has no filter for' do
      expect { select_books(filter: 'colour:red') }
        .to raise_error(Rails::Surrender::Error, 'colour is not a valid filter parameter.')
    end

    it 'reject a name with no value' do
      expect { select_books(filter: 'genre') }
        .to raise_error(Rails::Surrender::Error, 'The filter parameter was improperly formatted.')
    end
  end

  describe 'sorts' do
    it 'order by an attribute, ascending by default' do
      expect(titles(select_books(sort: 'title'))).to eq(['A Wizard of Earthsea', 'Dancing at the Edge', 'The Hobbit'])
    end

    it 'order descending with a leading -' do
      expect(titles(select_books(sort: '-pages'))).to eq(['The Hobbit', 'Dancing at the Edge', 'A Wizard of Earthsea'])
    end

    it 'order by an attribute of an association' do
      expect(titles(select_books(sort: '-author.name')).first).to eq('The Hobbit')
    end

    it 'use a sort_by_ scope the model defines, even over a column of the same name' do
      expect(titles(select_books(sort: 'genre'))).to eq(['Dancing at the Edge', 'A Wizard of Earthsea', 'The Hobbit'])
    end

    it 'echo the sort in the X-Sort header' do
      expect(select_books(sort: '-pages').headers).to include('X-Sort' => '-pages')
    end

    it 'ignore a blank sort' do
      expect(select_books(sort: '').headers).not_to have_key('X-Sort')
    end

    it 'reject a sort through an association that holds many records, which would repeat records' do
      expect { select_books(sort: 'chapters.title') }
        .to raise_error(Rails::Surrender::Error, 'chapters.title is not a valid sort parameter.')
    end

    it 'reject a sort that is not an attribute, an attribute of an association, or a scope' do
      expect { select_books(sort: 'author.colour') }
        .to raise_error(Rails::Surrender::Error, 'author.colour is not a valid sort parameter.')
    end
  end

  describe 'pages' do
    def pagination(selected)
      JSON.parse(selected.headers['X-Pagination'])
    end

    it 'slice the records and describe the page in the X-Pagination header' do
      selected = select_books(sort: 'title', page: '2', per: '2')

      expect(titles(selected)).to eq(['The Hobbit'])
      expect(pagination(selected)).to eq('total' => 3, 'page_total' => 1, 'page' => 2, 'previous_page' => 1,
                                         'next_page' => nil, 'last_page' => 2, 'per_page' => 2, 'offset' => 2)
    end

    it 'default to the first page of 50' do
      expect(pagination(select_books)).to include('page' => 1, 'per_page' => 50, 'page_total' => 3)
    end

    it 'report an empty page past the end' do
      expect(pagination(select_books(page: '3', per: '2'))).to include('page_total' => 0)
    end

    it 'count the whole selection once, not the page again' do
      queries = capture_queries { select_books(per: '2').headers }

      expect(queries.grep(/COUNT/).size).to eq(1)
    end

    it 'are skipped when the controller skips them' do
      selected = select_books(paginate: false)

      expect([selected.records.size, selected.headers]).to eq([3, {}])
    end
  end

  describe 'count responses' do
    it 'are asked for with the count param' do
      expect([described_class.new({ count: '' }).count?, described_class.new({}).count?]).to eq([true, false])
    end

    it 'count every record the filters select, ignoring the page' do
      selected = select_books(count: '', filter: 'genre:fantasy', per: '1')

      expect([selected.count, selected.headers]).to eq([2, {}])
    end

    it 'count one for a single record' do
      expect(described_class.new({ count: '' }).apply(hobbit).count).to eq(1)
    end
  end
end
