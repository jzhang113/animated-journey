# frozen_string_literal: true

# Create a new Grid of the given dimensions and randomly populate tiles
class RandomTiles
  include MapHelpers

  def initialize(dims, open_chance)
    @dims = dims
    @open_chance = open_chance
  end

  def run(args)
    map = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)

    map.width.times do |x|
      map.height.times do |y|
        map.grid[y][x] = 1 if rand < @open_chance
      end
    end

    args.state.grid = map
  end
end

# Create a new blank Grid of the given dimensions
class EmptyTiles
  def initialize(dims)
    @dims = dims
  end

  def run(args)
    args.state.grid = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)
  end
end
