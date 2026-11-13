# frozen_string_literal: true

RSpec.describe Rails::Surrender::ModelAdditions do
  describe '.surrenders' do
    it 'sorts default fields into attributes and associations' do
      expect(Chapter.surrender_attributes).to eq(%i[id title position])
      expect(Chapter.surrender_expands).to eq([:book])
    end

    it 'sorts available fields into attributes and associations' do
      expect(Author.surrender_callable_attributes).to eq(%i[id name created_at book_ids])
      expect(Author.surrender_callable_expands).to eq([:books])
    end

    it 'treats *_ids fields as attributes' do
      expect(Novel.surrender_attributes).to include(:chapter_ids)
    end

    it 'adds a subclass’s fields to those of its superclass' do
      expect(Novel.surrender_attributes).to eq(%i[id title genre chapter_ids])
      expect(Novel.surrender_expands).to eq([:author])
      expect(Novel.surrender_callable_expands).to eq(%i[author chapters prequel])
    end

    it 'rejects the keys used before fields were merged' do
      model = Class.new(ApplicationRecord)

      expect { model.surrenders(attributes: [:id]) }.to raise_error(ArgumentError, /attributes/)
    end
  end
end
