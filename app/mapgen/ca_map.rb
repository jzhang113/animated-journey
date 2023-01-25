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
    fiber = Fiber.new do |args|
      map = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)
      backbuf = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)

      @dims.w.times do |x|
        @dims.h.times do |y|
          map[x, y] = 1 if rand < @open_chance
        end
      end

      args.state.grid = map
      Fiber.yield

      @iters.times do
        ((map.width.div 2) - 1).times do |x|
          ((map.height.div 2) - 1).times do |y|
            next unless rand < @visit_chance

            # Unrolling updates
            update_cell(map, backbuf, 2 * x + 1, 2 * y + 1, 1)
            update_cell(map, backbuf, 2 * x + 2, 2 * y + 1, 1)
            update_cell(map, backbuf, 2 * x + 1, 2 * y + 2, 1)
            update_cell(map, backbuf, 2 * x + 2, 2 * y + 2, 1)
          end
        end

        map = backbuf
        args.state.grid = map
        Fiber.yield
      end

      caverns = find_caverns(map)

      args.state.grid = map
      Fiber.yield

      # TODO: better room connections
      caverns.each_cons(2) do |a, b|
        ax, ay = a.sample
        bx, by = b.sample

        path = make_path_horiz(ax, bx, ay)
        render map, path, 2

        path = make_path_vert(ay, by, bx)
        render map, path, 2
      end

      args.state.grid = map
    end

    Process.new(fiber, @debug ? 5 : 0)
  end

  def find_caverns(map)
    caverns = []

    map.width.times do |x|
      map.height.times do |y|
        next if map.grid[y][x].nil?

        region = []
        flood_check(map, x, y, region)

        if region.count > 6
          caverns << region
        elsif region.count > 0
          region.each { |rx, ry| map.grid[ry][rx] = nil }
        end
      end
    end

    caverns
  end

  def flood_check(map, x, y, region)
    return if map.grid[y][x].nil?
    return unless map.grid[y][x] == 1

    map.grid[y][x] = 2
    region << [x, y]

    flood_check(map, x - 1, y, region)
    flood_check(map, x + 1, y, region)
    flood_check(map, x, y - 1, region)
    flood_check(map, x, y + 1, region)
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
