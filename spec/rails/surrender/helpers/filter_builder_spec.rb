# frozen_string_literal: true

describe Rails::Surrender::FilterBuilder do
  subject { described_class.new(resource: resource, filter: filter) }

  let(:resource) { double('ActiveRecord::Relation') }
  let(:is_a_relation) { true }

  let(:filter) { [] }
  let(:filter_method) { nil }
  let(:responds_to_filter_method) { false }
  let(:filter_id_method) { nil }
  let(:responds_to_filter_id_method) { false }

  before do
    allow(resource).to receive(:is_a?).and_return(is_a_relation)
    allow(resource).to receive(:respond_to?).with(:filter_by_name).and_return(responds_to_filter_method)
    allow(resource).to receive(:respond_to?).with(:filter_by_user).and_return(responds_to_filter_method)
    allow(resource).to receive(:respond_to?).with(:filter_by_user_id).and_return(responds_to_filter_id_method)
  end

  describe '#build!' do
    context 'when resource is not an ActiveRecord::Relation' do
      let(:is_a_relation) { false }

      it 'returns the resource' do
        expect(subject.build!).to eq(resource)
      end
    end

    context 'when resource is an ActiveRecord::Relation' do
      context 'when the resource does not respond to the filter' do
        it 'calls no filter scopes' do
          expect(resource).not_to receive(:send)
          subject.build!
        end
      end

      context 'when the resource responds to the filter_by_key method' do
        let(:filter) { [name: 'shawn'] }
        let(:filter_method) { :filter_by_name }
        let(:responds_to_filter_method) { true }

        it 'calls the filter scope' do
          expect(resource).to receive(:send).with filter_method, 'shawn'
          subject.build!
        end
      end

      context 'when the resource responds to the filter_by_key_id method' do
        let(:filter) { [user: 1] }
        let(:filter_id_method) { :filter_by_user_id }
        let(:responds_to_filter_id_method) { true }

        it 'calls the filter scope' do
          expect(resource).to receive(:send).with filter_id_method, 1
          subject.build!
        end
      end
    end
  end
end
