# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  context 'Anonim user' do

    describe 'an unregistered visitor can not cause the action of a #show at GamesController' do
      before(:each) { get :show, id: game_w_questions.id }

      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect path must be a "new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'must be a flash alert' do
        expect(flash[:alert]).to be
      end
    end

    describe 'an unregistered visitor can not cause the action of a #create at GamesController' do
      before(:each) { post :create, id: game_w_questions.id }

      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect path must be a "new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'must be a flash alert' do
        expect(flash[:alert]).to be
      end
    end

    describe 'an unregistered visitor can not cause the action of a #answer at GamesController' do
      before(:each) { put :answer, id: game_w_questions.id }

      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect path must be a "new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'must be a flash alert' do
        expect(flash[:alert]).to be
      end
    end

    describe 'an unregistered visitor can not cause the action of a #take_money at GamesController' do
      before(:each) { put :take_money, id: game_w_questions.id }

      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect path must be a "new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'must be a flash alert' do
        expect(flash[:alert]).to be
      end
    end

    describe 'an unregistered visitor can not cause the action of a #help at GamesController' do
      before(:each) { put :help, id: game_w_questions.id }

      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
      it 'redirect path must be a "new_user_session_path' do
        expect(response).to redirect_to(new_user_session_path)
      end
      it 'must be a flash alert' do
        expect(flash[:alert]).to be
      end
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

    # юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
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

    # проверка, что пользовтеля посылают из чужой игры
    it '#show alien game' do
      # создаем новую игру, юзер не прописан, будет создан фабрикой новый
      alien_game = FactoryBot.create(:game_with_questions)

      # пробуем зайти на эту игру текущий залогиненным user
      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    # юзер берет деньги
    it 'takes money' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)

      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)

      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    # юзер пытается создать новую игру, не закончив старую
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be_falsey

      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game).to be_nil

      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
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

    describe '.fifty_fifty' do
      before(:each) {
        sign_in user
        expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
        put :help, id: game_w_questions.id, help_type: :fifty_fifty
      }

      it 'is clue was not spent' do
        expect(game_w_questions.fifty_fifty_used).to be_falsey
      end
      it 'the game must go on' do
        expect(assigns(:game).finished?).to be_falsey
      end
      it 'the prompt should be' do
        expect(assigns(:game).current_game_question.help_hash[:fifty_fifty]).to be
      end
      it 'user moves to the game page' do
        expect(response).to redirect_to(game_path)
      end
      it 'the hash size with the prompt is 2' do
        expect(assigns(:game).current_game_question.help_hash[:fifty_fifty].size).to eq(2)
      end
      it 'hash hints contains the correct answer' do
        expect(assigns(:game).current_game_question.help_hash[:fifty_fifty]).to include(assigns(:game).current_game_question.correct_answer_key)
      end
      it 'is flash object should not be alert' do
        expect(flash[:alert]).not_to be
      end
      it 'the response status should not be 200' do
        expect(response.status).not_to eq(200)
      end
    end

  end

  describe 'Checking game situations' do

    context 'a test that checks for an incorrect player response' do
      before do
        sign_in user
        put :answer, id: game_w_questions.id, letter: !game_w_questions.current_game_question.correct_answer_key
        game_w_questions.update_attribute(:current_level, 1)
      end
      it { expect(assigns(:game).finished?).to be_truthy }
      it { is_expected.to redirect_to(user_path(user)) }
      it { expect(flash[:alert]).to be }
      it { expect(game_w_questions.prize).to eq(0) }
      it { expect(response.status).not_to eq(200) }
    end
  end
end