# frozen_string_literal: true

RSpec.describe Rails::Surrender::Params::ListParam do
  def parse(text)
    described_class.parse(text, param: :filter)
  end

  it 'reads a missing or blank param as an empty list' do
    expect([parse(nil), parse('')]).to eq([[], []])
  end

  it 'reads bare names' do
    expect(parse('title,genre')).to eq(%w[title genre])
  end

  it 'reads names with values, typed as YAML types them' do
    expect(parse('long:true,genre:essays')).to eq([{ 'long' => true }, { 'genre' => 'essays' }])
  end

  it 'reads nested lists and maps' do
    expect(parse('books:[pages,chapters:[title]],author:{name:Tolkien}'))
      .to eq([{ 'books' => ['pages', { 'chapters' => ['title'] }] }, { 'author' => { 'name' => 'Tolkien' } }])
  end

  it 'keeps quoted values as given, colons and commas included' do
    expect(parse("published_after:'1968-11-01T13:30:00Z',title:\"Yes, Minister\""))
      .to eq([{ 'published_after' => '1968-11-01T13:30:00Z' }, { 'title' => 'Yes, Minister' }])
  end

  it 'rejects a malformed param, naming it' do
    expect { parse('genre:{') }
      .to raise_error(Rails::Surrender::Error, 'The filter parameter was improperly formatted.')
  end
end
