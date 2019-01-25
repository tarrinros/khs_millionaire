require 'rails_helper'

RSpec.feature 'USER looks at another profile', type: :feature do
  let(:user) do
      FactoryBot.create :user
  end

  # before(:each) do
  #   login_as user
  # end

  scenario 'successfully' do
    visit "users/#{user.id}"


  end
end