# frozen_string_literal: true

# Pathfinding utilities
module Pathfinding
  class Dijkstra
    def self.generate
      Process.new(Fiber.new do |args|
        Pathfinding.dijkstra(args, args.state.player_x, args.state.player_y, args.state.grid)
      end)
    end
  end

  class << self
    def to_idx(x, y, w)
      w * y + x
    end

    def from_idx(idx, w)
      [idx % w, idx.idiv(w)]
    end

    # map should be an array of array; each cell must contain a .exits method
    # returns [dists, prevs]
    # dists is an array of distances of each cell to the start
    # prevs is an array of cell references each pointing one step back to the start
    def dijkstra(args, start_x, start_y, map)
      queue = MinHeap.new
      rows = map.height
      cols = map.width

      dists = Array.new(rows) { Array.new(cols, 1_000_000) }
      prevs = Array.new(rows) { Array.new(cols) }
      dists[start_y][start_x] = 0

      map.each_with_index do |row, y|
        row.each_with_index do |_, x|
          queue.insert(dists[y][x], to_idx(x, y, cols)) if map.present?(x, y)
        end
      end

      steps = 0

      until queue.empty?
        prev_cost, prev_idx = queue.extract
        px, py = from_idx(prev_idx, cols)

        map.exits(px, py).each do |dx, dy|
          new_idx = to_idx(px + dx, py + dy, cols)
          cost = prev_cost + 1

          next unless cost < dists[py + dy][px + dx]

          dists[py + dy][px + dx] = cost
          prevs[py + dy][px + dx] = prev_idx

          queue.decrease_key(new_idx, cost)
        end

        steps += 1
        if steps % 200 == 0
          args.state.dijkstra = [dists, prevs]
          Fiber.yield
        end
      end

      args.state.dijkstra = [dists, prevs]
    end

    # prevs should be the result of a previous dijkstra call or another similar method that returns an array of steps from [start_x, start_y]
    # returns a list of cells on the path, including the start and end
    # returns nil if there is no path
    def path(start_x, start_y, end_x, end_y, prevs)
      path = [[end_x, end_y]]
      curr_x = end_x
      curr_y = end_y

      until curr_x == start_x && curr_y == start_y
        return nil if prevs[curr_y][curr_x].nil?

        curr_x, curr_y = prevs[curr_y][curr_x]
        path << [curr_x, curr_y]
      end

      path.reverse
    end
  end
end
