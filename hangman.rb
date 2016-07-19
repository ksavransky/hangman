class Hangman
  attr_reader :guesser, :referee, :board, :current_guess, :current_guess_pos

  def initialize(players = {})
    @referee = players.values[0]
    @guesser = players.values[1]
    @board = nil
    @current_guess = nil
    @current_guess_pos = nil
  end

  def setup
    secret_word_length = referee.pick_secret_word
    guesser.register_secret_length(secret_word_length)
    @board = "_" * secret_word_length
  end

  def take_turn
    @current_guess = guesser.guess(board)
    @current_guess_pos = referee.check_guess(@current_guess)
    update_board
    guesser.handle_response(@current_guess, @current_guess_pos)
  end

  def play
    setup
    while guesser.guesses_left != 0 && !won?
      take_turn
      puts "You have #{guesser.guesses_left} guesses left."
      puts "You won!" if won?
    end
    puts "The secret word was #{referee.secret_word}"
  end

  private

  def update_board
    @current_guess_pos.each do |pos|
      @board[pos] = @current_guess
    end
  end

  def won?
    !@board[0..-1].split("").include? ("_")
  end

end

class ComputerPlayer

  attr_reader :dictionary, :secret_word, :secret_length, :guesses_left, :candidate_words, :guessed_letters

  def initialize(dictionary = File.readlines("dictionary.txt").map(&:chomp))
    @dictionary = dictionary
    @secret_word = nil
    @secret_length = nil
    @guesses_left = 8
    @candidate_words = dictionary
  end

  def pick_secret_word
    @secret_word = dictionary.sample
    secret_word.length
  end

  def register_secret_length(word_length)
    @secret_length = word_length
    candidate_words.select! {|word| word.length == secret_length}
  end

  def guess(board)
    frequency_hash = Hash.new(0)

    candidate_words.join.split("").each do |e|
      frequency_hash[e] += 1 unless board.include?(e)
    end

    frequency_hash.sort_by {|k, v| v}.to_a.last[0]
  end

  def check_guess(ltr)
    result = []
    secret_word.split("").each_with_index do |l , i|
      result << i if l == ltr
    end
    result
  end

  def handle_response(*args)
      if args[1] == []
        puts "The secret word does not contain the letter #{args[0]}."
        @guesses_left = @guesses_left - 1
        candidate_words.select! {|word| !word.include?(args[0])}
      else
        puts "The secret word contains the letter #{args[0]}, at spots #{args[1]}."
        update_candidate_words(args[1], args[0])
      end

  end

  private

  def update_candidate_words(spots, letter)
    spots.each do |index|
      candidate_words.select! do |word|
         word[index] == letter
      end
    end

    candidate_words.each do |word|
      word.split("").each_with_index do |ltr, ind|
        candidate_words.delete(word) if ltr == letter && !spots.include?(ind)
      end
    end
  end

end


class HumanPlayer

  attr_reader :guesses_left, :secret_word

  def initialize(dictionary = File.readlines("dictionary.txt").map(&:chomp))
    @dictionary = dictionary
    @secret_word = nil
    @secret_length = nil
    @guesses_left = 8
  end

  def pick_secret_word
    puts "Please choose a secret word:"
    @secret_word = gets.chomp
    raise "Secret word not in dictionary" if !@dictionary.include? (@secret_word)
    secret_word.length
  end

  def register_secret_length(word_length)
    @secret_length = word_length
  end

  def guess(board)
    puts board[0..-1]
    puts "Please guess a letter."
    gets.chomp
  end

  def check_guess(ltr)
    result = []
    secret_word.split("").each_with_index do |l , i|
      result << i if l == ltr
    end
    result
  end

  def handle_response(*args)
      if args[1] == []
        puts "The secret word does not contain the letter #{args[0]}."
        @guesses_left = @guesses_left - 1
      else
        puts "The secret word contains the letter #{args[0]}, at spots #{args[1]}."
      end
  end

end

if __FILE__ == $PROGRAM_NAME
  Hangman.new({player1: ComputerPlayer.new, player2: HumanPlayer.new}).play
end
