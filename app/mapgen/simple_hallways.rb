# frozen_string_literal: true

class SimpleHallways
  include MapHelpers

  def initialize; end

  def run(args)
    map = args.state.grid

    args.state.connections.each do |a, b|
      ax, ay = args.state.room_points[a]
      bx, by = args.state.room_points[b]

      path = make_path_horiz(ax, bx, ay)
      render map, path, 2

      path = make_path_vert(ay, by, bx)
      render map, path, 2

      Fiber.yield
    end
  end
end
