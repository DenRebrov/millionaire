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

  context 'User helpers' do

    describe '.help_hash' do
      it '' do
        # на фабрике у нас изначально хэш пустой
        expect(game_question.help_hash).to eq({})

        # добавляем пару ключей
        game_question.help_hash[:some_key1] = 'blabla1'
        game_question.help_hash['some_key2'] = 'blabla2'

        # сохраняем модель и ожидаем сохранения хорошего
        expect(game_question.save).to be_truthy

        # загрузим этот же вопрос из базы для чистоты эксперимента
        gq = GameQuestion.find(game_question.id)

        # проверяем новые значение хэша
        expect(gq.help_hash).to eq({some_key1: 'blabla1', 'some_key2' => 'blabla2'})
      end
    end

    describe '.audience_help' do
      it '' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end

    describe '.fifty-fifty' do
      it '' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
        game_question.add_fifty_fifty

        expect(game_question.help_hash).to include(:fifty_fifty)
        ff = game_question.help_hash[:fifty_fifty]

        expect(ff).to include('b')
        expect(ff.size).to eq 2
      end
    end

    describe '.friend_call' do

      before (:each) {
        game_question.add_friend_call
      }

      it 'is contained in the help_hash' do
        expect(game_question.help_hash).to include(:friend_call)
      end
      it 'the output class must be a String' do
        expect(game_question.help_hash[:friend_call].class).to eq(String)
      end

      describe '80% probability of getting the correct key' do
        it 'is test #1' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #2' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #3' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #4' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #5' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #6' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #7' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #8' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #9' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
        it 'is test #10' do
          expect(game_question.help_hash[:friend_call]).to include(game_question.correct_answer_key.upcase)
        end
      end
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #
end
