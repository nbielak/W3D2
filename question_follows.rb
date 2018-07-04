require_relative 'questions_database'

class QuestionFollows

  attr_accessor :user_id, :question_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map {|datum| QuestionFollows.new(datum)}
  end

  def self.find_by_user_id
    question_follows = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        user_id = ?
    SQL
    QuestionFollows.new(question_follows)
  end

  def self.find_by_question_id
    question_follows = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      question_id = ?
    SQL
    QuestionFollows.new(question_follows)
  end

  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def is_follows?
    is_follows = QuestionsDatabase.instance.execute(<<-SQL, @question_id, @user_id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      question_id = ? AND user_id = ?
    SQL

    if is_follows.length > 0
      return true
    else
      return false
    end

  end

  def follow
    raise "Question is already being followed" if is_follows?
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        question_follows(user_id, question_id)
      VALUES
        (?, ?)
    SQL
  end

  def unfollow
    raise "You are not following the question" unless is_follows?
    QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
      DELETE FROM
        question_follows
      WHERE
        user_id = ? AND question_id = ?
    SQL
  end
end
