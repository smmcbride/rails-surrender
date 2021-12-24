# frozen_string_literal: true

describe Rails::Surrender::PaginationBuilder do
  subject { described_class.new(resource: resource, pagination: pagination) }

  let(:pagination) { Rails::Surrender::QueryParamParser::Pagination.new(page: 13, per: 123) }
  let(:resource) { double('ActiveRecord::Relation') }

  let(:responds_to_page) { true }

  before do
    allow(resource).to receive(:respond_to?).with(:page).and_return(responds_to_page)
  end

  describe '#build!' do
    context 'when resource does not have the page method' do
      let(:responds_to_page) { false }

      it 'returns the resource' do
        expect(subject.build!).to eq(resource)
      end
    end

    context 'when resource has the page method' do
      it 'applies a pagination scopes with the given attrributes' do
        expect(resource).to receive(:page).with(13).and_return(resource)
        expect(resource).to receive(:per).with(123)
        subject.build!
      end
    end
  end
end
