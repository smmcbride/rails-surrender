# frozen_string_literal: true

RSpec.describe Rails::Surrender::MenuParam do
  it 'is off by default, under the name menu' do
    expect(described_class.new).to have_attributes(enabled: false, name: 'menu')
  end

  describe '#asked_in?' do
    it 'is asked when menus are on and the param is present, whatever its value' do
      expect(described_class.new(enabled: true).asked_in?(menu: '')).to be(true)
    end

    it 'is not asked without the param' do
      expect(described_class.new(enabled: true).asked_in?(count: '')).to be(false)
    end

    it 'is never asked while menus are off' do
      expect(described_class.new(enabled: false).asked_in?(menu: '')).to be(false)
    end

    it 'answers a renamed param' do
      expect(described_class.new(enabled: true, name: :docs).asked_in?(docs: '')).to be(true)
    end
  end

  it 'refuses a name surrender already reads' do
    expect { described_class.new(name: 'count') }.to raise_error(ArgumentError, /"count"/)
  end

  it 'refuses a blank name' do
    expect { described_class.new(name: '') }.to raise_error(ArgumentError, /needs a name/)
  end
end
