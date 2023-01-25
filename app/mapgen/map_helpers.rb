# frozen_string_literal: true

module MapHelpers
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
