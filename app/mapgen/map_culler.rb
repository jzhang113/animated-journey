# frozen_string_literal: true

class MapCuller
  ROOM_OP = {
    ignore: 0,
    append: 1,
    overwrite: 2
  }.freeze

  def initialize(min_size, room_op)
    @min_size = min_size
    @room_op = room_op
  end

  def generate
    fiber = Fiber.new do |args|
      rooms = find_rooms(args.state.grid)

      case @room_op
      when ROOM_OP[:append]
        args.state.rooms ||= []
        args.state.rooms += rooms
      when ROOM_OP[:overwrite]
        args.state.rooms = rooms
      end
    end

    Process.new(fiber)
  end

  def find_rooms(map)
    rooms = []

    map.width.times do |x|
      map.height.times do |y|
        next if map.grid[y][x].nil?

        region = []
        flood_check(map, x, y, region)

        if region.count > @min_size
          rooms << region
        elsif region.count > 0
          region.each { |rx, ry| map.grid[ry][rx] = nil }
        end
      end
    end

    rooms
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
end
