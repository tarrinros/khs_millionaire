require 'rails_helper'

RSpec.feature 'USER looks at another profile', type: :feature do
  let!(:user) do
      FactoryBot.create :user, name: 'Alex', balance: 5000
  end

  before(:each) do
    FactoryBot.create_list(:game, 5, user_id: user.id, prize: 1000, current_level: 5, is_failed: true,
                           created_at: Time.parse('2019-01-17 12:53:38'),
                           updated_at: Time.parse('2019-01-17 12:53:38'),
                           finished_at: Time.parse('2019-01-17 12:53:38'))
  end

  scenario 'successfully' do
    visit "/"

    click_link 'Alex'

    expect(page).to have_current_path '/users/1'
    expect(page).to have_content 'Alex'
    expect(page).to have_content '1'
    expect(page).to have_content '2'
    expect(page).to have_content '3'
    expect(page).to have_content '4 проигрыш 17 янв., 13:53 5 1 000 ₽'
    expect(page).to_not have_content 'Сменить имя и пароль'

    save_and_open_page
  end
end