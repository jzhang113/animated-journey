# frozen_string_literal: true

module MapHelpers
  class << self
    def included(_mod)
      define_method :generate do
        fiber = Fiber.new do |args|
          run(args)
        end

        cb = ->(args) { render_map(args) }
        Process.new(fiber, $debug ? 5 : 0, $debug ? cb : nil)
      end
    end
  end

  def dist_euclidean(p1, p2)
    dx = p1.x - p2.x
    dy = p1.y - p2.y
    dx * dx + dy * dy
  end

  def dist_manhattan(p1, p2)
    dx = p1.x - p2.x
    dy = p1.y - p2.y
    dx.abs + dy.abs
  end

  def make_path_horiz(x1, x2, y)
    xa, xb = [x1, x2].minmax

    Rect.new(xa, y, xb - xa + 1, 1)
  end

  def make_path_vert(y1, y2, x)
    ya, yb = [y1, y2].minmax

    Rect.new(x, ya, 1, yb - ya + 1)
  end

  def render(map, rect, color)
    rect.w.times do |wx|
      rect.h.times do |wh|
        map[rect.x + wx, rect.y + wh] = color
      end
    end
  end

  def render_map(args)
    map = args.state.grid

    map.grid.map_2d do |row, col, t|
      next if t.nil?

      args.outputs[:map].sprites << tile_extended(
        col * map.tile_size,
        row * map.tile_size,
        map.tile_size,
        map.tile_size,
        t == 2 ? 255 : 125,
        125,
        t == 1 ? 255 : 125,
        255,
        $debug ? t % 10 : '.'
      )
    end
  end
end
