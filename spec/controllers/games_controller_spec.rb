require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  context 'Anonyms' do
    it 'kick from #show' do
      get :show, id: game_w_questions.id

      expect(response.status).to_not eq 200
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Вам необходимо войти в систему или зарегистрироваться.")
    end

    # ДЗ 62-4 Анонимный пользователь не может вызвать методы контроллера
    it 'kick from #create' do
      post :create

      expect(response.status).to eq 302
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Вам необходимо войти в систему или зарегистрироваться.")
    end

    it 'kick from #answer' do
      put :answer, id: game_w_questions, params: {letter: 'a'}

      expect(response.status).to eq 302
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Вам необходимо войти в систему или зарегистрироваться.")
    end

    it 'kick from #take_money' do
      put :take_money, id: game_w_questions.id

      expect(response.status).to eq 302
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to eq("Вам необходимо войти в систему или зарегистрироваться.")
    end
  end

# группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it 'creates game' do
      # сперва накидаем вопросов, из чего собирать новую игру
      generate_questions(15)

      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      # проверяем состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # и редирект на страницу этой игры
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    # ДЗ 62-3 пользователь не может начать 2 игры одновременно
    it 'does not starts two games' do
      expect(game_w_questions.finished?).to be_falsey # текущая игра не завершена
      expect { post :create }.to change(Game, :count).by(0) # новая игра не создалась
      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be # сообщение об ошибке
    end

    # юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    # ДЗ 62-1
    it '#show another users game' do
      another_user_game = FactoryBot.create(:game_with_questions) # Игра с другим пользователем

      get :show, id: another_user_game.id

      expect(response.status).to_not eq 200
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    # юзер отвечает на игру корректно - игра продолжается
    it 'answers correct' do
      # передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end

    # ДЗ 62-5 Игрок отвечает неправильно
    it 'answers incorrect' do
      # передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: "c"
      game = assigns(:game)

      expect(game.finished?).to be_truthy
      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to be
    end

    # тест на отработку "помощи зала"
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    # ДЗ 62-2 Пользователь забирает деньги до конца игры
    it 'takes the money' do
      game_w_questions.update_attribute(:current_level, 4)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.prize).to eq(500)

      user.reload # необходимо т.к. пользователь в базе изменился
      expect(user.balance).to eq(500)

      expect(game.finished?).to be_truthy
      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # ДЗ 63-4 может ли пользователь использовать подсказки
    it 'can use fifty_fifty' do
      expect(game_w_questions.fifty_fifty_used).to be_falsey

      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.fifty_fifty_used).to be_truthy
      expect(response).to redirect_to(game_path(game))
      expect(flash[:info]).to be
    end
  end
end
