# frozen_string_literal: true

RSpec.describe 'The app menu' do
  # Each top-level field's name and whether it renders by default.
  def defaults_of(fields)
    fields.to_h { |field| [field['name'], field['default']] }
  end

  def endpoint(path)
    json['endpoints'].find { |endpoint| endpoint['path'] == path }
  end

  before { get '/surrender_menu' }

  it 'is worked out from the routes, loading no records' do
    expect(count_queries { get '/surrender_menu' }).to eq(0)
  end

  it 'lists each GET route whose action surrenders a model, in the order they are drawn' do
    expect(json['endpoints'].pluck('path')).to eq(
      %w[/authors /authors/{id} /books/bestseller /books/unpaginated /books/skips_pagination /books/featured
         /books/decorated /books/without_author /books/{id}/cover /books /books/{id} /chapters]
    )
  end

  describe 'a collection' do
    it 'lists the fields, filters, sorts and page size' do
      books = endpoint('/books')

      expect(books['verb']).to eq('GET')
      expect(defaults_of(books['fields'])).to eq(
        'id' => true, 'title' => true, 'genre' => true, 'pages' => false, 'published_at' => false,
        'created_at' => false, 'chapter_ids' => false, 'author' => false, 'chapters' => false
      )
      expect(books['selection']['filters']).to include('title' => { 'type' => 'string' },
                                                       'published_before' => { 'type' => 'datetime' },
                                                       'long' => { 'type' => nil })
      expect(books['selection']['sorts']).to include('title', 'author.name', 'title_length')
      expect(books['selection']['page']).to eq('default' => 50, 'max' => 100)
    end

    it 'nests the field menu of each expand, without filters or sorts' do
      author = endpoint('/books')['fields'].find { |field| field['name'] == 'author' }

      expect(author).to eq(
        'name' => 'author', 'type' => 'object', 'default' => false,
        'fields' => [{ 'name' => 'id', 'type' => 'integer', 'default' => true },
                     { 'name' => 'name', 'type' => 'string', 'default' => true },
                     { 'name' => 'created_at', 'type' => 'datetime', 'default' => false },
                     { 'name' => 'book_ids', 'type' => 'array', 'default' => false }]
      )
    end

    it 'makes what the controller declares it includes a default, and what it excludes available' do
      expect(defaults_of(endpoint('/books/featured')['fields'])).to include('pages' => true, 'genre' => false)
    end

    it 'has no page size when the controller declares the action unpaginated' do
      expect(endpoint('/books/unpaginated')['selection']).to include('page' => nil)
    end

    it "can't see what the action decides as it runs" do
      expect(endpoint('/books/skips_pagination')['selection']['page']).to eq('default' => 50, 'max' => 100)
      expect(defaults_of(endpoint('/books/without_author')['fields'])).to include('author' => false)
    end

    it 'uses the model the controller declares, over the one named like the controller' do
      chapters = endpoint('/chapters')

      expect(defaults_of(chapters['fields'])).to include('title' => true, 'chapters' => true)
      expect(chapters['selection']['sorts']).to include('author.name')
    end
  end

  describe 'a single record' do
    it 'lists its fields and no selection' do
      book = endpoint('/books/{id}')

      expect(book['selection']).to be_nil
      expect(defaults_of(book['fields'])).to include('title' => true, 'author' => false)
    end

    it 'is told from a collection by the id in its path' do
      expect(endpoint('/books/{id}/cover')['selection']).to be_nil
    end

    it 'is one when the controller declares it, whatever its path' do
      expect(endpoint('/books/bestseller')['selection']).to be_nil
    end
  end

  it 'leaves out an action the controller takes off the menu' do
    expect(endpoint('/books/summary')).to be_nil
  end
end
