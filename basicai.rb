require 'io/console'
require 'json'

# Controller classes require a move function that will accept game_state and
# return a valid move [:up, :down, :left, :right]

class HumanController
  # https://gist.github.com/acook/4190379
  # Reads keypresses from the user including 2 and 3 escape character sequences.
  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end
  ensure
    STDIN.echo = true
    STDIN.cooked!

    return input
  end

  def move(game_state)
    move = nil
    while move == nil
      input = read_char
      case input
      when "\e[A"
        move = :left
      when "\e[B"
        move = :right
      when "\e[C"
        move = :down
      when "\e[D"
        move = :up
      end
    end
    return move
  end
end

class BasicAI

  def initialize
    @name = "BasicAI"
    @grid_length = nil
    @my_snake = {}
    @other_snakes = []
    @possible_moves = []
  end

  def neighbours(coord)
    x = coord[0]
    y = coord[1]
    {:up =>[x, y-1],
     :down =>[x, y+1],
     :left =>[x-1, y],
     :right =>[x+1, y]}
  end

  def coord_empty?(coord, blocked_coords)
    (coord & [-1, @grid_length]).empty? && !(blocked_coords.include? coord)
  end

  def move(game_state)
    state = JSON.parse(game_state, :symbolize_names => true)
    # Set grid size, should be moved to start() when implemented
    if state[:turn] == 1
      @grid_length = state[:board].length
    end
    @my_snake = state[:snakes].select {|snake| snake[:name] == @name}.first
    @other_snakes = state[:snakes].select {|snake| snake[:name] != @name}
    blocked_coords = []
    state[:snakes].each {|snake| blocked_coords.push(*(snake[:coords]))}
    @possible_moves = neighbours(@my_snake[:coords][0]).select do |dir, coord|
      coord_empty?(coord, blocked_coords)
    end
    @possible_moves.values.each do |coord|
      puts ""
    end
    return @possible_moves.keys.sample
  end
end
