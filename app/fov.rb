# frozen_string_literal: true

# https://www.albertford.com/shadowcasting/
class Fov
  class << self
    def visible_in_range(map, pos, light_walls: false)
      @visible = {}
      @map = map
      @start = pos
      @light_walls = light_walls

      draw_fov_quadrants(pos) if $debug[:show_fov_calc]

      @visible[pos.y * 80 + pos.x] = 0
      scan(:south, Row.new(1, [-1, 1], [1, 1]))
      scan(:north, Row.new(1, [-1, 1], [1, 1]))
      scan(:east, Row.new(1, [-1, 1], [1, 1]))
      scan(:west, Row.new(1, [-1, 1], [1, 1]))

      @visible
    end

    def is_opaque(x, y)
      !@map.present?(x, y)
    end

    def transform(quad, start, col, depth)
      case quad
      when :south
        [start.x + col, start.y - depth]
      when :north
        [start.x + col, start.y + depth]
      when :east
        [start.x + depth, start.y + col]
      when :west
        [start.x - depth, start.y + col]
      end
    end

    def slope(col, depth)
      [col - 0.5, depth]
    end

    Row = Struct.new(:depth, :start_slope, :end_slope) do
      def range
        min = depth * start_slope[0] / start_slope[1]
        max = depth * end_slope[0] / end_slope[1]
        round_ties_up(min)..round_ties_down(max)
      end

      def round_ties_up(n)
        (n + 0.5).floor
      end

      def round_ties_down(n)
        (n - 0.5).ceil
      end

      def next
        Row.new(depth + 1, start_slope, end_slope)
      end
    end

    def is_symmetric(row, col)
      row.range.cover?(col)
    end

    def scan(quad, row)
      rows = [row]

      until rows.empty?
        row = rows.pop()
        # next if row.depth > 10
        prev = nil

        row.range.each do |col|
          pos = transform(quad, @start, col, row.depth)

          if !@light_walls && !is_opaque(pos.x, pos.y)
            @visible[pos.y * 80 + pos.x] = row.depth
            $args.state.seen[pos.y * 80 + pos.x] = true
          end

          if @light_walls && is_symmetric(row, col)
            @visible[pos.y * 80 + pos.x] = row.depth
            $args.state.seen[pos.y * 80 + pos.x] = true
          end

          if !prev.nil? && is_opaque(prev.x, prev.y) && !is_opaque(pos.x, pos.y)
            row.start_slope = slope(col, row.depth)
            draw_fov_start_slopes(quad, prev) if $debug[:show_fov_calc]
          end

          if !prev.nil? && !is_opaque(prev.x, prev.y) && is_opaque(pos.x, pos.y)
            next_row = row.next
            next_row.end_slope = slope(col, row.depth)
            rows << next_row
            draw_fov_end_slopes(quad, pos) if $debug[:show_fov_calc]
          end

          prev = pos
        end

        if !prev.nil? && !is_opaque(prev.x, prev.y)
          rows << row.next
        end
      end
    end

    def transform_dist(n)
      (0.2 * n - 2)**3 + 10
    end

    def render(args, fov, target, brightness, color: Color.new(255, 255, 255))
      grid = args.state.grid

      args.outputs[target].background_color = $debug[:reveal_map] ? [100, 100, 100] : [0, 0, 0]

      fov.each do |idx, dist|
        x, y = [idx % grid.width, idx.idiv(grid.width)]

        args.outputs[target].solids << {
          x: x * grid.tile_size,
          y: y * grid.tile_size,
          w: grid.tile_size,
          h: grid.tile_size,
          r: color.r,
          g: color.g,
          b: color.b,
          a: 100 + 10 * brightness
        } if dist <= transform_dist(brightness)
      end
    end

    private

    # Helpers for $debug[:show_fov_calc]
    def draw_fov_quadrants(pos)
      $args.outputs[:fov_calc].lines << {
        x: (pos.x - 9.5) * @map.tile_size,
        y: (pos.y - 9.5) * @map.tile_size,
        x2: (pos.x + 10.5) * @map.tile_size,
        y2: (pos.y + 10.5) * @map.tile_size,
        r: 255, g: 255, b: 255
      }

      $args.outputs[:fov_calc].lines << {
        x: (pos.x + 10.5) * @map.tile_size,
        y: (pos.y - 9.5) * @map.tile_size,
        x2: (pos.x - 9.5) * @map.tile_size,
        y2: (pos.y + 10.5) * @map.tile_size,
        r: 255, g: 255, b: 255
      }
    end

    def draw_fov_start_slopes(quad, prev)
      $args.outputs[:fov_calc].borders << {
        x: prev.x * @map.tile_size,
        y: prev.y * @map.tile_size,
        w: @map.tile_size, h: @map.tile_size,
        r: 0, g: 255, b: 0
      }

      endpoint = start_slope_endpoint(quad, prev)
      $args.outputs[:fov_calc].lines << {
        x: (@start.x + 0.5) * @map.tile_size,
        y: (@start.y + 0.5) * @map.tile_size,
        x2: endpoint.x * @map.tile_size,
        y2: endpoint.y * @map.tile_size,
        r: 0, g: 240, b: 240, a: 150
      }
    end

    def draw_fov_end_slopes(quad, pos)
      $args.outputs[:fov_calc].borders << {
        x: pos.x * @map.tile_size,
        y: pos.y * @map.tile_size,
        w: @map.tile_size, h: @map.tile_size,
        r: 255, g: 0, b: 0
      }

      endpoint = end_slope_endpoint(quad, pos)
      $args.outputs[:fov_calc].lines << {
        x: (@start.x + 0.5) * @map.tile_size,
        y: (@start.y + 0.5) * @map.tile_size,
        x2: endpoint.x * @map.tile_size,
        y2: endpoint.y * @map.tile_size,
        r: 240, g: 0, b: 240, a: 150
      }
    end

    def start_slope_endpoint(quad, pos)
      line_x = pos.x + 0.5
      line_x += 0.5 if %i[north south].include? quad

      line_y = pos.y + 0.5
      line_y += 0.5 if %i[east west].include? quad

      [line_x, line_y]
    end

    def end_slope_endpoint(quad, pos)
      line_x = pos.x
      line_x += 0.5 if %i[east west].include? quad

      line_y = pos.y
      line_y += 0.5 if %i[north south].include? quad

      [line_x, line_y]
    end
  end
end
