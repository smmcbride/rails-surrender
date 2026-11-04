# frozen_string_literal: true

# Hides chapters titled "Secret" to exercise surrender's authorization of nested resources.
class ChaptersController < ApplicationController
  Ability = Struct.new(:hidden_title) do
    def can?(_action, subject)
      !(subject.is_a?(Chapter) && subject.title == hidden_title)
    end
  end

  def index
    surrender Book.all, include: [:chapters]
  end

  private

  def current_ability
    Ability.new('Secret')
  end
end
