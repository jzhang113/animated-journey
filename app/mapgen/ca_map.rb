# frozen_string_literal: true

class CaMap
  include MapHelpers

  def initialize(dims, rules, open_chance, visit_chance, iters, debug: false)
    @dims = dims
    @rules = rules
    @open_chance = open_chance
    @visit_chance = visit_chance
    @iters = iters
    @debug = debug
  end

  def generate
    fiber = Fiber.new do
      map = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)
      backbuf = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)

      @dims.w.times do |x|
        @dims.h.times do |y|
          map[x, y] = true if rand < @open_chance
        end
      end

      Fiber.yield map

      @iters.times do
        ((@dims.w.div 2) - 1).times do |x|
          ((@dims.h.div 2) - 1).times do |y|
            next unless rand < @visit_chance

            # Unrolling updates
            update_cell(map, backbuf, 2 * x + 1, 2 * y + 1, true)
            update_cell(map, backbuf, 2 * x + 2, 2 * y + 1, true)
            update_cell(map, backbuf, 2 * x + 1, 2 * y + 2, true)
            update_cell(map, backbuf, 2 * x + 2, 2 * y + 2, true)
          end
        end

        map = backbuf
        Fiber.yield map
      end

      map
    end

    callback = ->(args, result) { args.state.grid = result }
    Process.new(fiber, callback, @debug ? 1 : 0)
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
