require 'singleton'
# require_relative 'questions.db'
require 'sqlite3'
require 'byebug'

class QuestionsDatabase < SQLite3::Database#.new('./questions.db')
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end



class User

  attr_accessor :id, :fname, :lname
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map {|datum| User.new(datum)}
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    User.new(user.first)
  end

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    p user
    User.new(user.first)

  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{fname} #{lname} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{fname} #{lname} isn''t in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SETS
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_author_id(id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(id)
  end
end


class Question

  attr_accessor :id, :title, :body, :author_id
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map {|datum| Question.new(datum)}
  end

  def self.find_by_title(title)
    question = QuestionsDatabase.instance.execute(<<-SQL, title)
      SELECT
        *
      FROM
        questions
      WHERE
        title = ?
    SQL
    question.map {|question| Question.new(question)}
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    Question.new(question.first)
  end

  def self.find_by_author_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    question.map {|question| Question.new(question)}
  end

  def initialize(options)

    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        users(fname, lname, author_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollows.followers_for_question_id(id)
  end
end


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
    QuestionFollows.new(question_follows.first)
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
    QuestionFollows.new(question_follows.first)
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users
    JOIN
      question_follows
    ON
      users.id = question_follows.user_id
    WHERE
      question_id = ?
    SQL

    followers.map{|follower| User.new(follower)}
  end

  def self.followed_questions_for_user_id(user_id)
    followed_questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.id, questions.body, questions.title, questions.author_id
    FROM
      questions
    JOIN
      question_follows
    ON
      questions.id = question_follows.question_id
    WHERE
      user_id = ?
    SQL

    followed_questions.map{|question| Question.new(question)}
  end

  def self.most_followed_questions
    most_followed = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      questions.id, questions.body, questions.title, questions.author_id
    FROM
      questions
    JOIN
      question_follows
    ON
      questions.id = question_follows.question_id

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


class Reply
  attr_accessor :parent_id, :question_id, :author_id, :body

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map {|datum| Reply.new(datum)}
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return reply.length > 0 ? Reply.new(reply.first) : nil
  end

  def self.find_by_author_id(author_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL

    reply.map {|inner_reply| Reply.new(inner_reply)}
  end

  def self.find_by_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    reply.map {|reply| Reply.new(reply)}
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @author_id = options['author_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end

  def create
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @author_id, @body)
      INSERT INTO
        replies(question_id, parent_id, author_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(author_id)
  end

  def question

    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL

    return children.length > 0 ? children.map {|child| Reply.new(child)} : nil
  end
end



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
    QuestionLike.new(like.first)
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
