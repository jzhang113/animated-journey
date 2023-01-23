module MapHelpers
  def make_room_rect(map, dims)
    w = rand_range(3..10)
    h = rand_range(3..10)
    x = rand(dims.w - w)
    y = rand(dims.h - h)

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
end
