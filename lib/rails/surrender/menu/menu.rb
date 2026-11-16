# frozen_string_literal: true

require_relative 'endpoint_menu'
require_relative 'field_menu'
require_relative 'menu_param'
require_relative 'selection_menu'

module Rails
  module Surrender
    # Everything a request may ask of one model: its field menu and its selection menu. It is read from the same rules
    # that check requests, so it lists exactly what a request may ask.
    class Menu
      attr_reader :selection

      delegate :filters, :sorts, :page_size, to: :selection

      def initialize(model)
        @field_menu = FieldMenu.new(model)
        @selection = SelectionMenu.new(model)
      end

      def fields
        @field_menu.fields
      end
    end
  end
end
