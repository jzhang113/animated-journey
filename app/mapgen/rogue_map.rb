# frozen_string_literal: true

class RogueMap
  include MapHelpers

  def initialize(dims, n, w, h, debug = false)
    @dims = dims
    @room_range = n
    @room_width = w
    @room_height = h
    @debug = debug
  end

  def generate
    fiber = Fiber.new do
      rooms = []
      room_count = rand_range(@room_range)
      map = Grid.new(@dims.x, @dims.y, @dims.w, @dims.h)

      room_count.times do
        room = make_room_rect(@dims, @room_width, @room_height)
        rooms << room
        render map, room, Color.new(200, 0, 0)
        Fiber.yield map
      end

      rooms.drop(1).each_with_index do |room, idx|
        cx, cy = room.center
        bx, by = rooms[idx].center

        path = make_path_horiz(cx, bx, cy)
        render map, path, Color.new(200, 0, 0)
        path = make_path_vert(cy, by, bx)
        render map, path, Color.new(200, 0, 0)

        Fiber.yield map
      end

      map
    end

    callback = ->(args, result) { args.state.grid = result }
    Process.new(fiber, callback, @debug ? 10 : 0)
  end
end
