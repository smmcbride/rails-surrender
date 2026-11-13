# frozen_string_literal: true

RSpec.describe Rails::Surrender::Selection::PageSize do
  describe '#for' do
    subject(:page_size) { described_class.new(default: 20, max: 40) }

    it 'is the default when the request asks for no size' do
      expect(page_size.for(nil)).to eq(20)
    end

    it 'is the size the request asks for, up to the limit' do
      expect([page_size.for(30), page_size.for(40), page_size.for(1000)]).to eq([30, 40, 40])
    end

    it 'is never capped without a limit' do
      expect(described_class.new(default: 20, max: nil).for(1000)).to eq(1000)
    end
  end

  it 'defaults to pages of 50, limited to 100' do
    expect(described_class.new).to eq(described_class.new(default: 50, max: 100))
  end

  it 'rejects a default larger than the limit' do
    expect { described_class.new(default: 200, max: 100) }
      .to raise_error(ArgumentError, 'default_per_page (200) is larger than max_per_page (100)')
  end

  it 'rejects a default or limit that is not a positive whole number' do
    [{ default: 0 }, { default: '50' }, { max: -1 }, { max: 2.5 }].each do |settings|
      expect { described_class.new(**settings) }.to raise_error(ArgumentError, /positive whole number/)
    end
  end
end
