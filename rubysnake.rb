#!/usr/bin/env ruby

require './basicai'
require 'json'

class GameGrid
  # This GameGrid class can take a size (n) and an object (cell)
  # It will create a 2d array populated with cell hashmap objects
  def initialize(n)
    cell = {:state => :empty, :snake => nil}
    @grid_length = n
    @grid = [[nil] * n] * n
    @grid.map! { |x| x.map { |y| y = cell.clone}}
    @food = []
  end

  # @grid and @food need to be exported
  def grid
    @grid
  end

  def food
    @food
  end

  def make_data
    @grid.map do |row|
      row.map do |cell|
        if cell[:snake] != nil
          cell = {:state => cell[:state], :snake => cell[:snake].name}
        else
          cell = {:state => cell[:state]}
        end
      end
    end
  end

  # Picks a random available position to add a food object
  def add_food
    while true
      x = rand(@grid_length)
      y = rand(@grid_length)
      selection = @grid[x][y]
      if selection[:state] == :empty
        selection[:state] = :food
        @food << [x, y]
        break
      end
    end
  end

  # Picks random positions for snakes to spawn in
  def add_snake(snake)
    while true
      x = rand(@grid_length)
      y = rand(@grid_length)
      selection = @grid[x][y]
      if selection[:state] == :empty
        snake.coords << [x, y]
        selection[:snake] = snake
        selection[:state] = :head
        break
      end
    end
  end

  def move_snakes(snakes)
    blocked_coords = []
    heads = []
    snakes.each do |snake|
      # Clear the snakes off the current board
      snake.coords.each do |coord|
        @grid[coord[0]][coord[1]] = {:state => :empty, :snake => nil}
      end
      # Remove the tail if it should be removed
      if snake.growing == 0
        snake.coords.pop
      else
        snake.growing -= 1
      end
      # Save these coordinates for collision detection
      # Tails removed, heads handled seperately
      snake.coords.each do |coord|
        blocked_coords << coord
      end
      head_pos_x = snake.coords[0][0]
      head_pos_y = snake.coords[0][1]
      # Place the new head position in the snake object
      case snake.get_move
      when :up
        snake.coords.unshift([head_pos_x, head_pos_y-1])
      when :down
        snake.coords.unshift([head_pos_x, head_pos_y+1])
      when :left
        snake.coords.unshift([head_pos_x-1, head_pos_y])
      when :right
        snake.coords.unshift([head_pos_x+1, head_pos_y])
      end
      # Record the head positions for collision detection
      heads << snake.coords[0]
    end
    # Add any head collisions to be picked up by collision detection
    blocked_coords.push(*(heads.select{|head| heads.count(head) > 1}.uniq))
    # Collision Detection
    collision_det(snakes, blocked_coords)
    # Food Detection
    snakes.select {|snake| @food.include? snake.coords[0]}.each do |snake|
      snake.growing += 1
      @food.delete(snake.coords[0])
    end
    # Select snakes that are still alive
    live_snakes = snakes.select{ |snake| snake.state == :alive}
    # Write the snakes back to board
    write_snakes(live_snakes)
  end

  def collision_det(snakes, blocked_coords)
    # Set bounds
    bounds = [-1, @grid_length]
    # Select snakes with a head that is out of bounds or is blocked by a body
    # or head collision
    snakes.select do |snake|
      (!((snake.coords[0] & bounds).empty?) || (blocked_coords.include? snake.coords[0]))
    end.each do |snake|
      snake.state = :dead
    end
  end

  def write_snakes(snakes)
    # Write the new snake positions to the board
    snakes.each do |snake|
      snake.coords.drop(1).each do |coord|
        @grid[coord[0]][coord[1]] = {:state => :body, :snake => snake}
      end
      @grid[snake.coords[0][0]][snake.coords[0][1]] = {:state => :head, :snake => snake}
    end
  end

  def show_me
    (0..(@grid_length)).each {print "#"}
    puts "#"
    @grid.each do |x|
      print "#"
      x.each do |cell|
        if cell[:state] == :food
          print "@"
        elsif cell[:state] == :body
          print "S"
        elsif cell[:state] == :head
          print "H"
        else
          print " "
        end
      end
      puts "#"
    end
    (0..(@grid_length)).each {print "#"}
    puts "#"
  end

end

class Game
  # This class controls the game, includes methods for start, stop, step
  def initialize(name, size, snakes)
    @name = name
    @grid = GameGrid.new(size)
    @turn = 0
    @snakes = snakes
    @live_snakes = snakes
    @snakes.each {|snake| @grid.add_snake(snake)}
    @grid.show_me
  end

  def make_data
    # Create the hashmap data to pass to the controllers
    {:game_id => @name,
     :turn => @turn,
     :board => @grid.make_data,
     :snakes => @snakes.map {|snake| snake.make_data},
     :food => @grid.food}
  end

  def run
    while @live_snakes.count > 0
      sleep(0.1)
      step
    end
  end

  def step
    @turn += 1
    if @turn % 10 == 0
      @grid.add_food
    end
    # Select only live snakes to poll
    @live_snakes = @snakes.select{ |snake| snake.state == :alive}
    # Poll each snake
    @live_snakes.each {|snake| snake.move(make_data.to_json)}
    # Move the snakes on the grid
    @grid.move_snakes @live_snakes
    @live_snakes = @snakes.select{ |snake| snake.state == :alive}
    # Print the board to the console
    @grid.show_me
  end
end

class Snake
  # This class is for each snake
  def initialize(name, controller)
    @name = name
    @controller = controller
    @state = :alive
    @coords = []
    @score = 0
    @growing = 3
    @move = :up
  end

  def move(game_state)
    # Poll the controller for a move, set the selection in state
    @move = @controller.move(game_state)
  end

  def get_move
    @move
  end

  def make_data
    {:name => @name, :state => @state, :coords => @coords, :score => @score}
  end

  def name
    @name
  end

  attr_accessor :growing
  attr_accessor :state
  attr_accessor :coords

end

game = Game.new(:Game, 20, [Snake.new(:BasicAI, BasicAI.new)])
game.run
