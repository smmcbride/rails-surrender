# frozen_string_literal: true

describe Rails::Surrender::QueryParamParser do
  subject { described_class.new(query_params) }

  let(:query_params) { {} }

  describe '#include' do
    context 'when no include is passed' do
      it 'has no includes' do
        expect(subject.include).to eq([])
      end
    end

    context 'when include is passed' do
      let(:query_params) { { include: 'fake' } }

      it 'returns an include' do
        expect(subject.include).to eq(['fake'])
      end
    end
  end

  describe '#exclude' do
    context 'when no exclude is passed' do
      it 'has no exclude' do
        expect(subject.exclude).to eq([])
      end
    end

    context 'when exclude is passed' do
      let(:query_params) { { exclude: 'fake' } }

      it 'returns an exclude' do
        expect(subject.exclude).to eq(['fake'])
      end
    end
  end

  describe '#sort?' do
    context 'when no sort param is passed' do
      it 'will not sort' do
        expect(subject.sort?).to eq(false)
      end
    end

    context 'when a sort parameter is passed' do
      let(:query_params) { { sort: 'fake' } }

      it 'will sort' do
        expect(subject.sort?).to eq(true)
      end
    end
  end

  describe '#sort' do
    context 'when no sort parameter is passed' do
      it 'returns an empty Sort' do
        sort = subject.sort
        expect(sort.request).to be_nil
        expect(sort.direction).to eq 'ASC'
        expect(sort.attribute).to eq ''
        expect(sort.association).to eq ''
      end
    end

    context 'when given a sort key with no explicit direction' do
      let(:query_params) { { sort: 'fake' } }

      it 'returns a Sort struct with appropriate values' do
        sort = subject.sort
        expect(sort.request).to eq 'fake'
        expect(sort.direction).to eq 'ASC'
        expect(sort.attribute).to eq 'fake'
        expect(sort.association).to eq ''
      end
    end

    context 'when given a sort key with ascending direction' do
      let(:query_params) { { sort: '+fake' } }

      it 'returns a Sort struct with appropriate values' do
        sort = subject.sort
        expect(sort.request).to eq '+fake'
        expect(sort.direction).to eq 'ASC'
        expect(sort.attribute).to eq 'fake'
        expect(sort.association).to eq ''
      end
    end

    context 'when given a sort key with descending direction' do
      let(:query_params) { { sort: '-fake' } }

      it 'returns a Sort struct with appropriate values' do
        sort = subject.sort
        expect(sort.request).to eq '-fake'
        expect(sort.direction).to eq 'DESC'
        expect(sort.attribute).to eq 'fake'
        expect(sort.association).to eq ''
      end
    end
  end

  describe '#filter?' do
    context 'when no filter param is passed' do
      it 'will not filter' do
        expect(subject.filter?).to eq(false)
      end
    end

    context 'when a filter parameter is passed' do
      let(:query_params) { { filter: 'fake' } }

      it 'will filter' do
        expect(subject.filter?).to eq(true)
      end
    end
  end

  describe '#filter' do
    context 'when no filter param is passed' do
      it 'will have an empty filter' do
        expect(subject.filter).to eq([])
      end
    end

    context 'when a filter parameter is passed' do
      let(:query_params) { { filter: 'foo:true' } }

      it 'will parse the filter' do
        expect(subject.filter).to eq([{ 'foo' => true }])
      end
    end

    context 'when multiple filter parameter are passed' do
      let(:query_params) { { filter: 'foo:true,bar:blue' } }

      it 'will parse the filter' do
        expect(subject.filter).to eq([{ 'foo' => true }, { 'bar' => 'blue' }])
      end
    end

    context 'when nested filter parameters are passed' do
      let(:query_params) { { filter: 'foo:{bar:blue}' } }

      it 'will parse the filter' do
        expect(subject.filter).to eq([{ 'foo' => { 'bar' => 'blue' } }])
      end
    end

    context 'when a malformed filter parameter is passed' do
      let(:query_params) { { filter: 'foo:{' } }

      it 'will raise an error' do
        expect do
          subject.filter
        end.to raise_error(Rails::Surrender::Error, 'The filter parameter was improperly formatted.')
      end
    end
  end

  describe '#ids?' do
    context 'when ids are not requested' do
      it 'will not signal for ids' do
        expect(subject.ids?).to eq(false)
      end
    end

    context 'when ids are requested' do
      let(:query_params) { { ids: nil } }
      it 'will signal for ids' do
        expect(subject.ids?).to eq(true)
      end
    end
  end

  describe '#count?' do
    context 'when count is not requested' do
      it 'will not signal for count' do
        expect(subject.count?).to eq(false)
      end
    end

    context 'when count is requested' do
      let(:query_params) { { count: nil } }
      it 'will signal for count' do
        expect(subject.count?).to eq(true)
      end
    end
  end

  describe '#paginate?' do
    context 'when pagination is not requested' do
      it 'will not signal for pagination' do
        expect(subject.paginate?).to eq(false)
      end
    end

    context 'when pagination is requested' do
      let(:query_params) { { page: 1, per: 50 } }
      it 'will signal for pagination' do
        expect(subject.paginate?).to eq(true)
      end
    end
  end

  describe '#pagination' do
    context 'when pagination is not requested' do
      it 'will provide a default Pagination' do
        pagination = subject.pagination
        expect(pagination.page).to eq 1
        expect(pagination.per).to eq 50
      end
    end

    context 'when pagination is requested' do
      let(:query_params) { { page: 13, per: 13 } }
      it 'will signal for pagination' do
        pagination = subject.pagination
        expect(pagination.page).to eq 13
        expect(pagination.per).to eq 13
      end
    end
  end
end
