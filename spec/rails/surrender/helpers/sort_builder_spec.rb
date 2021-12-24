# frozen_string_literal: true

describe Rails::Surrender::SortBuilder do
  subject { described_class.new(resource: resource, sort: sort) }

  let(:sort) do
    Rails::Surrender::QueryParamParser::Sort.new(
      request: sort_request,
      direction: sort_direction,
      association: sort_association,
      attribute: sort_attribute,
      scope_method: sort_scope_method
    )
  end
  let(:sort_request) { 'fake' }
  let(:sort_direction) { 'asc' }
  let(:sort_association) { nil }
  let(:sort_attribute) { nil }
  let(:sort_scope_method) { 'fake' }

  let(:resource) { double('ActiveRecord::Relation') }
  let(:is_a_relation) { true }
  let(:responds_to_scope) { false }
  let(:reflection_keys) { [] }
  let(:attributes) { [] }
  let(:association_attributes) { [] }

  before do
    allow(resource).to receive(:is_a?).and_return(is_a_relation)
    allow(resource).to receive_message_chain(:klass, :attribute_names).and_return(attributes)
    allow(resource).to receive(:respond_to?).and_return(responds_to_scope)
    allow(resource).to receive_message_chain(:reflections, :keys).and_return(reflection_keys)
    allow(resource).to receive_message_chain(:reflect_on_association, :klass, :attribute_names)
      .and_return(association_attributes)
    allow(resource).to receive_message_chain(:reflect_on_association, :klass, :table_name)
  end

  describe '#build!' do
    context 'when resource is not an ActiveRecord::Reation' do
      let(:is_a_relation) { false }

      it 'returns the resource' do
        expect(subject.build!).to eq(resource)
      end
    end

    context 'when resource is an ActiveRecord::Relation' do
      context 'when the resource has the sort attribute' do
        let(:attributes) { ['foo'] }
        let(:sort_attribute) { 'foo' }

        it 'applies a sort scope with the attrribute' do
          expect(resource).to receive(:order).with(sort.attribute => sort.direction)
          subject.build!
        end
      end

      context 'when the resource has the sort attribute' do
        let(:attributes) { ['foo'] }
        let(:sort_attribute) { 'bar' }
        let(:responds_to_scope) { true }

        it 'applies a sort scope with the attrribute' do
          expect(resource).to receive(:send).with(sort.scope_method, sort.direction)
          subject.build!
        end
      end

      context 'when the resource has an association with the sort attribute' do
        let(:attributes) { ['foo'] }
        let(:sort_attribute) { 'bar' }
        let(:sort_association) { 'zip' }
        let(:responds_to_scope) { false }
        let(:reflection_keys) { ['zip'] }
        let(:association_attributes) { ['bar'] }

        it 'applies a sort scope with the attribute' do
          expect(resource).to receive_message_chain(:joins, :order)
          subject.build!
        end
      end

      context 'when the resource cannot respond to the association or attribute' do
        let(:attributes) { ['foo'] }
        let(:sort_attribute) { 'bar' }
        let(:sort_association) { 'zip' }
        let(:responds_to_scope) { false }
        let(:reflection_keys) { ['zip'] }
        let(:association_attributes) { ['tie'] }

        it 'applies a sort scope with the attribute' do
          expect { subject.build! }.to raise_error(Rails::Surrender::Error, 'fake is not a valid sort parameter.')
        end
      end
    end
  end
end
