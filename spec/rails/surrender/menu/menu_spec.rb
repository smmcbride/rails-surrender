# frozen_string_literal: true

RSpec.describe Rails::Surrender::Menu do
  let(:menu) { Book.surrender_menu }

  it 'lists the fields of the model’s field menu' do
    expect(menu.fields.map { |field| [field.name, field.kind, field.default?] })
      .to eq(Rails::Surrender::FieldMenu.new(Book).fields.map { |field| [field.name, field.kind, field.default?] })
  end

  it 'holds the model’s selection menu' do
    expect(menu.selection).to be_a(Rails::Surrender::SelectionMenu)
    expect(menu.selection.sorts).to eq(Rails::Surrender::SelectionMenu.new(Book).sorts)
  end

  it 'answers filters, sorts and page size from its selection menu' do
    expect(menu.filters).to eq(menu.selection.filters)
    expect(menu.sorts).to eq(menu.selection.sorts)
    expect(menu.page_size).to eq(menu.selection.page_size)
  end
end
