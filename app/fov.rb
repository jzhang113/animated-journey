# frozen_string_literal: true

class Fov
  class << self
    def visible_in_range(map, pos, range)
      visible = {}

      ((pos.x - range)..(pos.x + range)).each do |x|
        ((pos.y - range)..(pos.y + range)).each do |y|
          visible[y * 80 + x] = true
        end
      end

      visible
    end

    def render(args)
      grid = args.state.grid

      args.outputs[:fov].background_color = $debug[:reveal_map] ? [150, 150, 150] : [0, 0, 0]
      args.state.fov.each do |idx, _|
        x, y = [idx % grid.width, idx.idiv(grid.width)]

        args.outputs[:fov].solids << {
          x: x * grid.tile_size,
          y: y * grid.tile_size,
          w: grid.tile_size,
          h: grid.tile_size,
          r: 255,
          g: 255,
          b: 255
        }
      end
    end
  end
end
