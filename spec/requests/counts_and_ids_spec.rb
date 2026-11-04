# frozen_string_literal: true

RSpec.describe 'Counts and ids' do
  it 'renders a count instead of the resources' do
    get '/books', params: { count: '' }

    expect(json).to eq('count' => 3)
  end

  it 'counts filtered resources' do
    get '/books', params: { count: '', filter: 'genre:fantasy' }

    expect(json).to eq('count' => 2)
  end

  it 'counts every resource, not just the first page' do
    get '/books', params: { count: '', per: 2 }

    expect(json).to eq('count' => 3)
  end

  it 'renders ids instead of the resources' do
    get '/books', params: { ids: '' }

    expect(json['ids']).to contain_exactly(hobbit.id, earthsea.id, essays.id)
  end

  it 'renders the id of a single resource' do
    get "/books/#{essays.id}", params: { ids: '' }

    expect(json).to eq('ids' => [essays.id])
  end
end
