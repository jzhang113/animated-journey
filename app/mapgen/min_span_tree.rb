# frozen_string_literal: true

class MinSpanTree
  include MapHelpers

  def initialize
  end

  def generate
    fiber = Fiber.new do |args|
      map = args.state.grid

      # TODO: better room connections
      args.state.rooms.each_cons(2) do |a, b|
        ax, ay = a.sample
        bx, by = b.sample

        path = make_path_horiz(ax, bx, ay)
        render map, path, 2

        path = make_path_vert(ay, by, bx)
        render map, path, 2
      end
    end

    Process.new(fiber)
  end
end
