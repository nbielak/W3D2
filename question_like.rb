require_relative 'questions_database'

class QuestionLike
  attr_accessor :question_id, :liker_id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map {|datum| QuestionLike.new(datum)}
  end

  def self.find_by_question_id
    like = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_id = ?
    SQL
    QuestionLike.new(like)
  end

  def initialize(options)
    @question_id = options['question_id']
    @liker_id = options['liker_id']
  end

  def likes?
    likes = QuestionsDatabase.instance.execute(<<-SQL, @question_id, @liker_id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      question_id = ? AND liker_id = ?
    SQL

    if likes.length > 0
      return true
    else
      return false
    end

  end

  def like
    raise "Question is already being liked" if likes?
    QuestionsDatabase.instance.execute(<<-SQL, @liker_id, @question_id)
      INSERT INTO
        question_likes(liker_id, question_id)
      VALUES
        (?, ?)
    SQL
  end

  def unlike
    raise "You haven't liked the question" unless likes?
    QuestionsDatabase.instance.execute(<<-SQL, @liker_id, @question_id)
      DELETE FROM
        question_likes
      WHERE
        liker_id = ? AND question_id = ?
    SQL
  end
end
