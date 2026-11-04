# frozen_string_literal: true

RSpec.describe 'Pagination' do
  let(:pagination) { JSON.parse(response.headers['X-Pagination']) }

  it 'pages collections and describes the page in the X-Pagination header' do
    get '/books', params: { sort: 'title', page: 2, per: 2 }

    expect(titles).to eq(['The Hobbit'])
    expect(pagination).to eq('total' => 3, 'page_total' => 1, 'page' => 2, 'previous_page' => 1,
                             'next_page' => nil, 'last_page' => 2, 'per_page' => 2, 'offset' => 2)
  end

  it 'pages by default' do
    get '/books'

    expect(pagination).to include('page' => 1, 'per_page' => 50)
  end

  it 'can be skipped by the controller' do
    get '/books/unpaginated'

    expect(response.headers).not_to have_key('X-Pagination')
  end
end
