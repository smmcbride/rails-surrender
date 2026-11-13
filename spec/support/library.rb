# frozen_string_literal: true

# A small catalogue of authors, books and chapters shared by the request specs.
RSpec.shared_context 'with a library' do
  let!(:tolkien) { Author.create!(name: 'Tolkien') }
  let!(:le_guin) { Author.create!(name: 'Le Guin') }
  let!(:hobbit) do
    Novel.create!(author: tolkien, title: 'The Hobbit', genre: 'fantasy', pages: 310,
                  published_at: Time.utc(1937, 9, 21))
  end
  let!(:earthsea) do
    Novel.create!(author: le_guin, title: 'A Wizard of Earthsea', genre: 'fantasy', pages: 183,
                  published_at: Time.utc(1968, 11, 1))
  end
  let!(:essays) do
    Book.create!(author: le_guin, title: 'Dancing at the Edge', genre: 'essays', pages: 306,
                 published_at: Time.utc(1989, 1, 1))
  end
  let!(:unexpected_party) { Chapter.create!(book: hobbit, title: 'An Unexpected Party', position: 1) }
  let!(:roast_mutton) { Chapter.create!(book: hobbit, title: 'Roast Mutton', position: 2) }

  let(:json) { JSON.parse(response.body) }
  let(:titles) { json.map { |book| book['title'] } }
end

RSpec.configure { |config| config.include_context 'with a library', type: :request }
