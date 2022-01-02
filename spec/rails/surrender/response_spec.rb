# frozen_string_literal: true

describe Rails::Surrender::Response do
  subject { described_class.new(data: data) }

  let(:data) { {} }

  describe '#json_data' do
    before do
      expect(Oj).to receive(:dump).with(data, mode: :compat)
    end
    it 'calls OJ to render the JSON' do
      subject.json_data
    end
  end
end
