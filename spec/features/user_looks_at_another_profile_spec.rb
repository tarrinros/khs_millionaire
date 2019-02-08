require 'rails_helper'

RSpec.feature 'USER looks at another profile', type: :feature do
  let!(:user) do
      FactoryBot.create :user, name: 'Alex', balance: 5000
  end


  # before(:each) do
  #   login_as user
  # end

  before(:each) do
    FactoryBot.create(:game, user_id: user.id)
  end

  scenario 'successfully' do
    visit "/"

    click_link 'Alex'

    save_and_open_page

    # expect(page).to have_content 'Alex'
  end

  scenario 'successfully' do
    visit "users/#{user.id}"

    expect(page).to have_content 'Alex'
  end
end