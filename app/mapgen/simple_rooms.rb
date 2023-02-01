# frozen_string_literal: true

class SimpleRooms
  include MapHelpers

  def initialize(n, w, h)
    @room_range = n
    @room_width = w
    @room_height = h
  end

  def run(args)
    args.state.rooms ||= []
    room_count = rand_range(@room_range)

    room_count.times do
      room = make_room_rect(args.state.grid.width, args.state.grid.height, @room_width, @room_height)
      next if overlaps?(args.state.grid, room)

      args.state.rooms << room
      render args.state.grid, room, 1
    end
  end

  def make_room_rect(map_w, map_h, width_range, height_range)
    w = rand_range(width_range)
    h = rand_range(height_range)
    x = rand(map_w - w)
    y = rand(map_h - h)

    Rect.new(x, y, w, h)
  end

  def overlaps?(map, rect)
    ((rect.x - 1)..(rect.x + rect.w)).each do |rx|
      ((rect.y - 1)..(rect.y + rect.h)).each do |ry|
        return true unless map.grid[ry][rx].nil?
      end
    end

    false
  end
end
