require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }

  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end

  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!('d')

      expect(game_w_questions.current_level).to eq(level + 1)
      expect(game_w_questions.current_game_question).not_to eq(q)
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      game_w_questions.current_game_question
      game_w_questions.answer_current_question!('d')

      game_w_questions.take_money!

      expect(user.balance).to eq game_w_questions.prize

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  context '.current_game_question' do
    it 'returns current game question' do
      expect(game_w_questions.current_game_question).to eq game_w_questions.game_questions[0]
    end
  end

  context '.previous_level' do
    it 'returns number of previous level' do
      expect(game_w_questions.previous_level).to eq game_w_questions.current_level - 1
    end
  end

  context '.answer_current_question!' do
    context 'correct answer' do
      let(:q) { game_w_questions.current_game_question }

      it 'returns true if answer is correct' do
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
      end

      it 'saves game status to :in_progress' do
        game_w_questions.answer_current_question!('d')

        expect(game_w_questions.status).to eq :in_progress
      end

      it 'increases game level by 1' do
        expect {
          game_w_questions.answer_current_question!('d')
        }.to change(game_w_questions, :current_level).by(1)
      end
    end

    context 'wrong answer' do
      let(:q) { game_w_questions.current_game_question }
      let(:wrong_answer_key) { %w(a b c d).delete_if { |i| i == 'd' }.sample }

      it 'returns false if answer is wrong' do
        expect(game_w_questions.answer_current_question!(wrong_answer_key)).to be_falsey
      end

      it 'saves game status to :fail' do
        game_w_questions.current_level = 14
        game_w_questions.answer_current_question!(wrong_answer_key)

        expect(game_w_questions.current_level).to eq 14
        expect(game_w_questions.prize).to eq game_w_questions.user.balance
        expect(game_w_questions.status).to eq :fail
      end
    end

    context 'the last question' do
      let(:q) { game_w_questions.current_game_question }

      it 'save game status to :won and finish the game' do
        game_w_questions.current_level = 14
        game_w_questions.answer_current_question!('d')

        expect(game_w_questions.current_level).to eq 15
        expect(game_w_questions.is_failed).to be_falsey
        expect(game_w_questions.status).to eq :won
      end
    end

    context 'when time is out' do
      let(:q) { game_w_questions.current_game_question }

      it 'sets game status to :timeout' do
        game_w_questions.current_level = 14
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.answer_current_question!('d')

        expect(game_w_questions.current_level).to eq 14
        expect(game_w_questions.is_failed).to be_truthy
        expect(game_w_questions.prize).to eq game_w_questions.user.balance
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end
end