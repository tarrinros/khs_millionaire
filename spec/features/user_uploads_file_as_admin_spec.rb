require 'rails_helper'

RSpec.feature 'USER uploads file as admin', type: :feature do
  let!(:user) do
    FactoryBot.create :user, name: 'Alex', is_admin: true
  end

  before(:each) do
    login_as user
  end

  scenario 'successfully' do
    visit "/"

    click_link 'Залить новые вопросы'

    fill_in 'questions_level', with: '7'

    page.attach_file('questions_file', Rails.root + 'public/7.txt')

    click_button 'Save changes'

    expect(page).to have_current_path '/questions/new'
    expect(page).to have_content 'Уровень 7, обработано 477, создано 474, время 02.000 сек'
  end

  scenario 'unsuccessfully' do
    visit "/"

    click_link 'Залить новые вопросы'

    fill_in 'questions_level', with: '7'

    page.attach_file('questions_file', Rails.root + 'app/assets/images/logo.png')

    click_button 'Save changes'

    expect(page).to have_current_path '/questions/new'
    # expect(page).to have_content 'Уровень 7, обработано 477, создано 474, время 02.000 сек'
  end
end