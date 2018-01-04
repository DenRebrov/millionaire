
#require 'game_help_generator'

# Игровой вопрос — модель, которая связывает игру и вопрос. При создании новой
# игры формируется массив из 15 игровых вопросов для конкретной игры.
class GameQuestion < ActiveRecord::Base
  # Игровой вопрос, конечно, принадлежит конкретной игре.
  belongs_to :game

  # Игровой вопрос знает, из какого вопроса берется информация
  belongs_to :question

  # Создаем в этой модели виртуальные геттеры text, level, значения которых
  # автоматически берутся из связанной модели question.
  #
  # Таким обазом при вызове, например
  #
  # game_question.text
  #
  # получим то, что лежит в
  #
  # game_question.question.text
  #
  delegate :text, :level, to: :question, allow_nil: true

  # Без игры и вопроса — игровой вопрос не имеет смысла
  validates :game, :question, presence: true

  # В полях a, b, c и d прячутся индексы ответов из объекта :game. Каждый из
  # них — целое число от 1 до 4.
  validates :a, :b, :c, :d, inclusion: {in: 1..4}

  # Автоматическая сериализация поля в базу (мы юзаем как обычный хэш,
  # а рельсы в базе хранят как строчку)
  # см. ссылки в материалах урока
  serialize :help_hash, Hash

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  # Основные методы для доступа к данным в шаблонах и контроллерах:

  # Метод variants возвращает хэш с ключами a..d и значениями — тектом ответов:
  #
  # {
  #   'a' => 'Текст ответа Х',
  #   'b' => 'Текст ответа У',
  #   ...
  # }
  def variants
    {
      'a' => question.read_attribute("answer#{a}"),
      'b' => question.read_attribute("answer#{b}"),
      'c' => question.read_attribute("answer#{c}"),
      'd' => question.read_attribute("answer#{d}")
    }
  end

  # Метод answer_correct? проверяет правильность ответа по букве. Возвращает
  # true, если переданная буква (строка или символ) содержит верный ответ и
  # false во всех других случаях.
  def answer_correct?(letter)
    correct_answer_key == letter.to_s.downcase
  end

  # Метод correct_answer_key возвращает ключ правильного ответа 'a', 'b', 'c',
  # или 'd'. Обратите внимание, что в переменных a, b, c и d игрового вопроса
  # лежат числа от 1 до 4, но мы не знаем, в какой букве какое число.
  def correct_answer_key
    {a => 'a', b => 'b', c => 'c', d => 'd'}[1]
  end

  # Метод correct_answer возвращает текст правильного ответа
  def correct_answer
    variants[correct_answer_key]
  end

  # Добавляем в help_hash по ключю fifty_fifty - массив из двух вариантов: правильный и случайный
  # и сохраняем объект
  def add_fifty_fifty
    self.help_hash[:fifty_fifty] = [
        correct_answer_key,
        (%w(a b c d) - [correct_answer_key]).sample
    ]
    save
  end

  # Генерируем в help_hash случайное распределение по вариантам и сохраняем объект
  def add_audience_help
    # массив ключей
    keys_to_use = keys_to_use_in_help
    self.help_hash[:audience_help] = {
        'a' => rand(100),
        'b' => rand(100),
        'c' => rand(100),
        'd' => rand(100)
    } #GameHelpGenerator.audience_distribution(keys_to_use, correct_answer_key)
    save
  end

  # Добавляем в help_hash подсказку друга и сохраняем объект
  def add_friend_call
    # массив ключей
    keys_to_use = keys_to_use_in_help
    self.help_hash[:friend_call] = {
        'a' => rand(100)
    } #GameHelpGenerator.friend_call(keys_to_use, correct_answer_key)
    save
  end

  private

  # Рассчитываем какие ключи нам доступны в подсказках
  def keys_to_use_in_help
    keys_to_use = variants.keys
    # Учитываем наличие подсказки 50/50
    keys_to_use = help_hash[:fifty_fifty] if help_hash.has_key?(:fifty_fifty)
    keys_to_use
  end
end
