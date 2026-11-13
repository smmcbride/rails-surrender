# frozen_string_literal: true

RSpec.describe 'Sorting' do
  it 'sorts ascending by an attribute' do
    get '/books', params: { sort: 'title' }

    expect(titles).to eq(['A Wizard of Earthsea', 'Dancing at the Edge', 'The Hobbit'])
  end

  it 'sorts descending by an attribute' do
    get '/books', params: { sort: '-pages' }

    expect(titles).to eq(['The Hobbit', 'Dancing at the Edge', 'A Wizard of Earthsea'])
  end

  it 'echoes the sort in the X-Sort header' do
    get '/books', params: { sort: '-pages' }

    expect(response.headers['X-Sort']).to eq('-pages')
  end

  it 'sorts with sort_by_ scopes defined on the model' do
    get '/books', params: { sort: 'title_length' }

    expect(titles).to eq(['The Hobbit', 'Dancing at the Edge', 'A Wizard of Earthsea'])
  end

  it 'sorts by an attribute of an association' do
    get '/books', params: { sort: '-author.name' }

    expect(titles.first).to eq('The Hobbit')
  end

  it 'ignores a blank sort' do
    get '/books', params: { sort: '' }

    expect(response).to have_http_status(:ok)
    expect(response.headers).not_to have_key('X-Sort')
  end

  it 'rejects sorts on unknown attributes' do
    get '/books', params: { sort: 'colour' }

    expect(response).to have_http_status(:bad_request)
    expect(json['error']).to eq('colour is not a valid sort parameter.')
  end
end
