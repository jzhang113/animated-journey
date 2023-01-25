# frozen_string_literal: true

# Create a new Grid of the given dimensions and randomly populate tiles
class RandomTiles
  def initialize(dims, open_chance)
    @dims = dims
    @open_chance = open_chance
  end

  def generate
    fiber = Fiber.new do |args|
      map = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)

      map.width.times do |x|
        map.height.times do |y|
          map.grid[y][x] = 1 if rand < @open_chance
        end
      end

      args.state.grid = map
    end

    Process.new(fiber)
  end
end

# Create a new blank Grid of the given dimensions
class EmptyTiles
  def initialize(dims)
    @dims = dims
  end

  def generate
    fiber = Fiber.new do |args|
      args.state.grid = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)
    end

    Process.new(fiber)
  end
end
