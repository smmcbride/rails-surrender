# frozen_string_literal: true

describe Rails::Surrender::SortBuilder do
  subject { described_class.new(resource: resource, sort: sort) }

  let(:resource) { {} }
  let(:sort) { {} }
end
