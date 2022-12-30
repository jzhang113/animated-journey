class Grid
  include Enumerable

  attr_reader :x, :y, :width, :height, :tile_size

  def initialize(x, y, width, height, tile_size = 12)
    @x = x
    @y = y
    @width = width
    @height = height
    @tile_size = tile_size
    @grid = Array.new(height) { Array.new(width) }
  end

  def [](x, y)
    @grid[y][x]
  end

  def []=(x, y, value)
    @grid[y][x] = value
  end

  def each(&block)
    @grid.each { |row| block.call(row) }
  end
end
