require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    assign(:user, (FactoryBot.build_stubbed :user, name: 'Alex'))

    assign(:games, [
      FactoryBot.build_stubbed(
        :game, id: 13, created_at: Time.parse('2016.10.09, 13:00'), current_level: 3, prize: 1000
      )
    ])
    render
  end

  it 'doesn`t render change password button' do
    expect(rendered).not_to match 'Сменить имя и пароль'
  end

  it 'renders change password button for signed in user' do
    sign_in :user
    render

    expect(rendered).to match 'Сменить имя и пароль'
  end

  # Проверяем, что шаблон выводит имя пользователя
  it 'renders users name' do
    expect(rendered).to match 'Alex'
  end

  # Проверяем, что шаблон выводит данные об игре
  it 'renders games list' do
    expect(rendered).to match 'в процессе'
    expect(rendered).to match '09 окт., 13:00'
    expect(rendered).to match '1 000 ₽'
    expect(rendered).to match '3'
  end
end