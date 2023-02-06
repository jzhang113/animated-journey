# frozen_string_literal: true

module MapHelpers
  class << self
    def included(_mod)
      define_method :generate do
        fiber = Fiber.new do |args|
          run(args)
        end

        if $debug[:show_mapgen]
          cb = ->(args) { render_map(args) }
          Process.new(fiber, 5, cb)
        else
          Process.new(fiber)
        end
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

    args.outputs[:map].background_color = [0, 0, 0]
    map.grid.map_2d do |row, col, t|
      if t.nil?
        args.outputs[:map].sprites << tile_extended(
          col * map.tile_size,
          row * map.tile_size,
          map.tile_size,
          map.tile_size,
          255,
          255,
          255,
          230,
          '#'
        )
      else
        args.outputs[:map].sprites << tile_extended(
          col * map.tile_size,
          row * map.tile_size,
          map.tile_size,
          map.tile_size,
          t == 2 ? 255 : 125,
          125,
          t == 1 ? 255 : 125,
          255,
          $debug[:show_mapgen] ? t % 10 : '.'
        )
      end
    end
  end
end
