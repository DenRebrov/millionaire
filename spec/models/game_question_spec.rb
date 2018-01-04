# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) do
    FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  # Группа тестов на игровое состояние объекта вопроса
  describe 'game status' do
    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    describe '.answer_correct?' do

      context 'when correct answer provided' do
        let (:provided_answer) { "b" }

        it 'returns true' do
          expect(game_question.answer_correct?(provided_answer)).to be_truthy
        end
      end

      context 'when incorrect answer provided' do
        let (:provided_answer) { "a" }

        it 'returns false' do
          expect(game_question.answer_correct?(provided_answer)).to be_falsey
        end
      end
    end

    describe '.text' do
      it 'is equal to the value of the same field in the related "question"' do
        expect(game_question.text).to eq(game_question.question.text)
      end
    end

    describe '.level' do
      it 'is equal to the value of the same field in the related "question"' do
        expect(game_question.level).to eq(game_question.question.level)
      end
    end

    describe '.correct_answer_key' do
      let (:provided_answer) { "b" }

      it 'is equal to provided_answer' do
        expect(game_question.correct_answer_key).to eq(provided_answer)
      end
    end
  end

  context 'user helpers' do

    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      ah = game_question.help_hash[:audience_help]
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end


end
