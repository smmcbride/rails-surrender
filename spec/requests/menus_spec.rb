# frozen_string_literal: true

RSpec.describe 'Endpoint menus' do
  # Each top-level field's name and whether it renders by default.
  def defaults_of(fields)
    fields.to_h { |field| [field['name'], field['default']] }
  end

  def ask_for_menu(path, params = {})
    count_queries { get path, params: { menu: '' }.merge(params) }
  end

  describe 'a collection' do
    it 'lists the fields, filters, sorts and page size, loading no records' do
      expect(ask_for_menu('/books')).to eq(0)

      expect(defaults_of(json['fields'])).to eq(
        'id' => true, 'title' => true, 'genre' => true, 'pages' => false, 'published_at' => false,
        'created_at' => false, 'chapter_ids' => false, 'author' => false, 'chapters' => false
      )
      expect(json['selection']['filters']).to include('title' => { 'type' => 'string' },
                                                      'published_before' => { 'type' => 'datetime' },
                                                      'long' => { 'type' => nil })
      expect(json['selection']['sorts']).to include('title', 'author.name', 'title_length')
      expect(json['selection']['page']).to eq('default' => 50, 'max' => 100)
    end

    it 'nests the field menu of each expand, without filters or sorts' do
      ask_for_menu('/books')
      author = json['fields'].find { |field| field['name'] == 'author' }

      expect(author).to eq(
        'name' => 'author', 'kind' => 'expand', 'default' => false,
        'fields' => [{ 'name' => 'id', 'kind' => 'attribute', 'default' => true },
                     { 'name' => 'name', 'kind' => 'attribute', 'default' => true },
                     { 'name' => 'created_at', 'kind' => 'attribute', 'default' => false },
                     { 'name' => 'book_ids', 'kind' => 'id_list', 'default' => false }]
      )
    end

    it 'makes what the controller includes a default, and what it excludes available' do
      ask_for_menu('/books/featured')

      expect(defaults_of(json['fields'])).to include('pages' => true, 'genre' => false)
    end

    it 'keeps a field the controller excludes, as a request may still include it' do
      ask_for_menu('/books/without_author')

      expect(defaults_of(json['fields'])).to include('author' => false)
    end

    it 'has no page size when the controller skips pagination' do
      ask_for_menu('/books/unpaginated')

      expect(json['selection']).to include('page' => nil)
    end
  end

  describe 'a single record' do
    it 'lists its fields and no selection, loading only the record the controller finds' do
      expect(ask_for_menu("/books/#{essays.id}")).to eq(1)

      expect(json['selection']).to be_nil
      expect(defaults_of(json['fields'])).to include('title' => true, 'author' => false)
    end

    it 'lists the fields of its own STI class' do
      ask_for_menu("/books/#{hobbit.id}")

      expect(defaults_of(json['fields'])).to include('chapter_ids' => true, 'author' => true)
    end
  end

  it 'has neither part for a resource with no model' do
    ask_for_menu('/books/summary')

    expect(json).to eq('fields' => nil, 'selection' => nil)
  end

  it 'is not decorated by the controller' do
    ask_for_menu('/books/decorated')

    expect(json.keys).to eq(%w[fields selection])
  end

  it 'ignores the other asks, even ones that would be refused' do
    ask_for_menu('/books', filter: 'nonsense:1', sort: 'nonsense', include: 'nonsense', count: '', per: 1)

    expect(response).to have_http_status(:ok)
    expect(json.keys).to eq(%w[fields selection])
    expect(response.headers).not_to include('X-Sort', 'X-Pagination')
  end

  context 'with menus off' do
    around do |example|
      configured = Rails::Surrender.menu_param
      Rails::Surrender.menu_param = Rails::Surrender::MenuParam.new(enabled: false)
      example.run
    ensure
      Rails::Surrender.menu_param = configured
    end

    it 'renders the records, leaving the param to the app' do
      get '/books', params: { menu: '' }

      expect(titles).to contain_exactly('The Hobbit', 'A Wizard of Earthsea', 'Dancing at the Edge')
    end
  end

  context 'with the param renamed' do
    around do |example|
      configured = Rails::Surrender.menu_param
      Rails::Surrender.menu_param = Rails::Surrender::MenuParam.new(enabled: true, name: 'docs')
      example.run
    ensure
      Rails::Surrender.menu_param = configured
    end

    it 'answers the new name' do
      get '/books', params: { docs: '' }

      expect(json.keys).to eq(%w[fields selection])
    end

    it 'leaves the old name to the app' do
      get '/books', params: { menu: '' }

      expect(titles).to include('The Hobbit')
    end
  end
end
