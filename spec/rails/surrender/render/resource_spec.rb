# frozen_string_literal: true

RSpec.describe Rails::Surrender::Render::Resource do
  subject(:data) { described_class.new(resource: resource, ability: nil).parse.data }

  context 'when the resource is nil' do
    let(:resource) { nil }

    it 'renders an empty object' do
      expect(data).to eq({})
    end
  end

  context 'when the resource is a hash' do
    let(:resource) { { status: 'ok' } }

    it 'renders the hash as given' do
      expect(data).to eq(resource)
    end
  end

  context 'when the resource is an array' do
    let(:resource) { [1, 2] }

    it 'renders the array as given' do
      expect(data).to eq(resource)
    end
  end
end
