# frozen_string_literal: true

class CaMap
  include MapHelpers

  def initialize(rules, visit_chance, iters, debug: false)
    @rules = rules
    @visit_chance = visit_chance
    @iters = iters
    @debug = debug
  end

  def generate
    fiber = Fiber.new do |args|
      backbuf = Grid.new(args.state.grid.x, args.state.grid.y, args.state.grid.width, args.state.grid.height)

      @iters.times do
        ((args.state.grid.width.div 2) - 1).times do |x|
          ((args.state.grid.height.div 2) - 1).times do |y|
            next unless rand < @visit_chance

            # Unrolling updates
            update_cell(args.state.grid, backbuf, 2 * x + 1, 2 * y + 1, 1)
            update_cell(args.state.grid, backbuf, 2 * x + 2, 2 * y + 1, 1)
            update_cell(args.state.grid, backbuf, 2 * x + 1, 2 * y + 2, 1)
            update_cell(args.state.grid, backbuf, 2 * x + 2, 2 * y + 2, 1)
          end
        end

        args.state.grid = backbuf
        Fiber.yield
      end
    end

    Process.new(fiber, @debug ? 5 : 0)
  end

  def update_cell(map, backbuf, x, y, data)
    count = neighbors(map, x, y)
    backbuf.grid[y][x] = if map.grid[y][x].nil?
                           # b
                           bit_on?(@rules[0], count) ? data : nil
                         else
                           # s
                           bit_on?(@rules[1], count - 1) ? map.grid[y][x] : nil
                         end
  end

  def neighbors(map, x, y)
    count = 0

    ((x - 1)..(x + 1)).each do |rx|
      ((y - 1)..(y + 1)).each do |ry|
        count += 1 unless map.grid[ry][rx].nil?
      end
    end

    count
  end

  def bit_on?(bitmask, pos)
    bitmask & (1 << pos) != 0
  end
end
