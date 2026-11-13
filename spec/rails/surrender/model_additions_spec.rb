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

    it 'lists the default fields in the order they are declared, after a superclass’s' do
      expect(Novel.surrender_fields).to eq(%i[id title genre chapter_ids author])
    end

    it 'rejects the keys used before fields were merged' do
      model = Class.new(ApplicationRecord)

      expect { model.surrenders(attributes: [:id]) }.to raise_error(ArgumentError, /attributes/)
    end
  end

  describe '.surrenders?' do
    it 'is true for default and available fields only' do
      expect([Author.surrenders?(:name), Author.surrenders?('book_ids'), Author.surrenders?(:updated_at)])
        .to eq([true, true, false])
    end
  end

  describe '.surrender_field' do
    it 'makes an association an expand' do
      expect(Book.surrender_field(:author)).to be_a(Rails::Surrender::Fields::Expand)
    end

    it 'makes the *_ids name of an association an id list of it' do
      id_list = Rails::Surrender::Fields::IdList.new(name: :chapter_ids, association: :chapters)

      expect(Book.surrender_field('chapter_ids')).to eq(id_list)
    end

    it 'makes anything else an attribute' do
      expect(Book.surrender_field(:pages)).to eq(Rails::Surrender::Fields::Attribute.new(name: :pages))
    end
  end
end
