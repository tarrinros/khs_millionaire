require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    assign(:user, (FactoryBot.build_stubbed :user, name: 'Alex'))
    render
  end

  # Проверяем, что шаблон выводит имя пользователя
  it 'renders users name' do
    expect(rendered).to match 'Alex'
  end
end