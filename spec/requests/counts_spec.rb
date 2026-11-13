# frozen_string_literal: true

RSpec.describe 'Counts' do
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
    expect(response.headers).not_to have_key('X-Pagination')
  end

  it 'ignores the ids param it used to answer' do
    get '/books', params: { ids: '' }

    expect(json.first).to include('id', 'title')
  end
end
