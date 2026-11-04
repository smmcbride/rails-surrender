# frozen_string_literal: true

RSpec.describe 'Filtering' do
  it 'filters on column equality' do
    get '/books', params: { filter: 'genre:essays' }

    expect(titles).to eq(['Dancing at the Edge'])
  end

  it 'filters on an association by its foreign key' do
    get '/books', params: { filter: "author:#{le_guin.id}" }

    expect(titles).to contain_exactly('A Wizard of Earthsea', 'Dancing at the Edge')
  end

  it 'combines filters' do
    get '/books', params: { filter: "author:#{le_guin.id},genre:fantasy" }

    expect(titles).to eq(['A Wizard of Earthsea'])
  end

  it 'uses filter_by_ scopes defined on the model' do
    get '/books', params: { filter: 'long:true' }

    expect(titles).to contain_exactly('The Hobbit', 'Dancing at the Edge')
  end

  describe 'datetime columns' do
    it 'filters before a time' do
      get '/books', params: { filter: "published_before:'1968-11-01'" }

      expect(titles).to eq(['The Hobbit'])
    end

    it 'filters up to and including a time' do
      get '/books', params: { filter: "published_to:'1968-11-01'" }

      expect(titles).to contain_exactly('The Hobbit', 'A Wizard of Earthsea')
    end

    it 'filters after a time' do
      get '/books', params: { filter: "published_after:'1968-11-01'" }

      expect(titles).to eq(['Dancing at the Edge'])
    end

    it 'filters from and including a time' do
      get '/books', params: { filter: "published_from:'1968-11-01'" }

      expect(titles).to contain_exactly('A Wizard of Earthsea', 'Dancing at the Edge')
    end
  end

  it 'rejects filters the model does not have' do
    get '/books', params: { filter: 'colour:red' }

    expect(response).to have_http_status(:bad_request)
    expect(json['error']).to eq('colour is not a valid filter parameter.')
  end

  describe 'generated scopes' do
    it 'are callable on the model directly' do
      expect(Book.filter_by_genre('essays')).to eq([essays])
    end

    it 'are callable on relations' do
      expect(Book.where(author: le_guin).filter_by_published_after(Time.utc(1970))).to eq([essays])
    end

    it 'are inherited by STI subclasses' do
      expect(Novel.filter_by_genre('fantasy')).to contain_exactly(hobbit, earthsea)
    end

    it 'leave filters defined by the model in place' do
      Book.filter_by_title('The Hobbit')

      expect(Book.filter_by_genre('FANTASY')).to contain_exactly(hobbit, earthsea)
    end

    it 'leave filters inherited from a superclass in place' do
      Novel.filter_by_title('The Hobbit')

      expect(Novel.filter_by_genre('FANTASY')).to contain_exactly(hobbit, earthsea)
    end

    it 'are defined once for concurrent first lookups' do
      model = Class.new(ApplicationRecord) { self.table_name = 'books' }
      entered = Queue.new
      release = Queue.new
      allow(model).to receive(:define_surrender_column_scopes).and_wrap_original do |original|
        entered << true
        release.pop
        original.call
      end

      first = Thread.new { model.respond_to?(:filter_by_title) }
      entered.pop
      second = Thread.new { model.respond_to?(:filter_by_title) }
      sleep 0.05 until second.status == 'sleep' || !second.alive?
      release << true

      expect([first.value, second.value]).to eq([true, true])
    end

    it 'do not answer for columns that do not exist' do
      expect(Book).not_to respond_to(:filter_by_colour)
    end
  end
end
