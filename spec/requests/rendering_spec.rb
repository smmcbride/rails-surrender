# frozen_string_literal: true

RSpec.describe 'Rendering' do
  describe 'default attributes' do
    it 'renders the attributes a model surrenders for a collection' do
      get '/authors'

      expect(json).to contain_exactly({ 'id' => tolkien.id, 'name' => 'Tolkien' },
                                      { 'id' => le_guin.id, 'name' => 'Le Guin' })
    end

    it 'renders the attributes a model surrenders for an instance' do
      get "/authors/#{tolkien.id}"

      expect(json).to eq('id' => tolkien.id, 'name' => 'Tolkien')
    end

    it 'renders the default expands of an instance' do
      get "/books/#{hobbit.id}"

      expect(json).to include('chapter_ids' => [unexpected_party.id, roast_mutton.id],
                              'author' => { 'id' => tolkien.id, 'name' => 'Tolkien' })
    end
  end

  describe 'include' do
    it 'adds available attributes' do
      get "/authors/#{tolkien.id}", params: { include: 'created_at' }

      expect(json.keys).to contain_exactly('id', 'name', 'created_at')
    end

    it 'adds *_ids attributes for associations' do
      get "/authors/#{le_guin.id}", params: { include: 'book_ids' }

      expect(json['book_ids']).to contain_exactly(earthsea.id, essays.id)
    end

    it 'adds available expands' do
      get "/authors/#{tolkien.id}", params: { include: 'books' }

      expect(json['books']).to eq([{ 'id' => hobbit.id, 'title' => 'The Hobbit', 'genre' => 'fantasy' }])
    end

    it 'adds attributes to nested resources' do
      get "/authors/#{tolkien.id}", params: { include: 'books:[pages]' }

      expect(json['books'].first).to include('pages' => 310)
    end

    it 'expands through several levels' do
      get "/authors/#{tolkien.id}", params: { include: 'books:[chapters:[position]]' }

      chapters = json['books'].first['chapters']
      expect(chapters).to contain_exactly({ 'id' => unexpected_party.id, 'title' => 'An Unexpected Party',
                                            'position' => 1 },
                                          { 'id' => roast_mutton.id, 'title' => 'Roast Mutton', 'position' => 2 })
    end

    it 'does not expand back into a resource already rendered higher up' do
      get "/authors/#{tolkien.id}", params: { include: 'books:[chapters]' }

      expect(json['books'].first['chapters'].first).not_to have_key('book')
    end

    it 'expands the same association on every resource in a collection' do
      get '/authors', params: { include: 'books' }

      expect(json.to_h { |author| [author['name'], author['books'].size] }).to eq('Tolkien' => 1, 'Le Guin' => 2)
    end

    it 'treats STI subclasses as their base class when stopping circular expansion' do
      get "/books/#{hobbit.id}", params: { include: 'chapters' }

      expect(json['chapters'].first).not_to have_key('book')
    end

    it 'does not expand an association to an STI subclass of a resource already rendered' do
      essays.update!(prequel: earthsea)

      get "/books/#{essays.id}", params: { include: 'prequel' }

      expect(json).not_to have_key('prequel')
    end

    it 'rejects attributes the model does not make available' do
      get "/books/#{essays.id}", params: { include: 'updated_at' }

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq('[:updated_at] is not a valid include parameter.')
    end

    it 'rejects names that are not attributes or associations' do
      get '/authors', params: { include: 'nonsense' }

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq('[:nonsense] is not a valid include parameter.')
    end

    it 'rejects malformed values' do
      get '/authors', params: { include: 'books:[' }

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to eq('The include parameter was improperly formatted.')
    end
  end

  describe 'exclude' do
    it 'removes default attributes' do
      get "/authors/#{tolkien.id}", params: { exclude: 'name' }

      expect(json).to eq('id' => tolkien.id)
    end

    it 'removes default expands' do
      get "/books/#{hobbit.id}", params: { exclude: 'author' }

      expect(json).not_to have_key('author')
    end
  end

  describe 'controller options' do
    it 'applies the include and exclude given by the controller' do
      get '/books/featured'

      expect(json.first.keys).to contain_exactly('id', 'title', 'pages')
    end

    it 'lets the request include what the controller excluded' do
      get '/books/featured', params: { include: 'genre' }

      expect(json.first.keys).to contain_exactly('id', 'title', 'genre', 'pages')
    end

    it 'lets the controller decorate the rendered data' do
      get '/books/decorated'

      expect(json['books'].size).to eq(3)
    end
  end

  describe 'authorization' do
    before { Chapter.create!(book: hobbit, title: 'Secret', position: 3) }

    it 'omits nested resources the ability cannot read' do
      get '/chapters'

      hobbit_json = json.find { |book| book['id'] == hobbit.id }
      expect(hobbit_json['chapters'].pluck('title')).to contain_exactly('An Unexpected Party', 'Roast Mutton')
    end
  end

  describe 'eager loading' do
    def queries_for_authors_with_books_and_chapters
      count_queries { get '/authors', params: { include: 'books:[chapters]' } }
    end

    it 'runs the same number of queries however many records are rendered' do
      baseline = queries_for_authors_with_books_and_chapters

      3.times do |n|
        author = Author.create!(name: "Author #{n}")
        book = Book.create!(author: author, title: "Book #{n}")
        Chapter.create!(book: book, title: "Chapter #{n}")
      end

      expect(queries_for_authors_with_books_and_chapters).to eq(baseline)
    end
  end
end
