# frozen_string_literal: true

module MapHelpers
  def make_room_rect(map_dims, width_range, height_range)
    w = rand_range(width_range)
    h = rand_range(height_range)
    x = rand(map_dims.w - w)
    y = rand(map_dims.h - h)

    Rect.new(x, y, w, h)
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
end
