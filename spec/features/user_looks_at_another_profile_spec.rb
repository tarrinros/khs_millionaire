require 'rails_helper'

RSpec.feature 'USER looks at another profile', type: :feature do
  let!(:user) do
    FactoryBot.create :user, name: 'Alex', balance: 2000, is_admin: false
  end

  let!(:games) do
    [
      FactoryBot.create(:game, id: 1, user_id: user.id, prize: 64000, current_level: 11, is_failed: false,
                        created_at: Time.parse('2018-08-19 22:37:58'),
                        updated_at: Time.parse('2018-08-19 22:47:44'),
                        finished_at: Time.parse('2018-08-19 22:47:44')),

      FactoryBot.create(:game, id: 2, user_id: user.id, prize: 1000, current_level: 5, is_failed: false,
                        created_at: Time.parse('2018-09-30 22:44:58'))
    ]
  end

  scenario 'successfully' do
    visit "/"

    click_link 'Alex'

    expect(page).to have_current_path '/users/1'
    expect(page).to have_content 'Alex'
    expect(page).to have_content '1 деньги 19 авг., 22:37 11 64 000 ₽'
    expect(page).to have_content '2 в процессе 30 сент., 22:44 5 1 000 ₽'
    expect(page).to_not have_content 'Сменить имя и пароль'
  end
end