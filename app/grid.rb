# frozen_string_literal: true

class Grid
  include Enumerable

  attr_reader :x, :y, :width, :height, :tile_size, :grid

  def initialize(x, y, width, height, tile_size = 12)
    @x = x
    @y = y
    @width = width
    @height = height
    @tile_size = tile_size
    @grid = Array.new(height) { Array.new(width) }
  end

  def [](x, y)
    raise "Index #{x}, #{y} is out of bounds" unless in_bounds(x, y)

    @grid[y][x]
  end

  def []=(x, y, value)
    raise "Index #{x}, #{y} is out of bounds" unless in_bounds(x, y)

    @grid[y][x] = value
  end

  def present?(x, y)
    return false unless in_bounds(x, y)

    !@grid[y][x].nil?
  end

  def in_bounds(x, y)
    x >= 0 && x < width && y >= 0 && y < height
  end

  def each(&block)
    @grid.each { |row| block.call(row) }
  end
end
