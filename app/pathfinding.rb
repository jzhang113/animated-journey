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
    include MapHelpers

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
      cols = map.width

      dists = {}
      prevs = {}
      start_idx = to_idx(start_x, start_y, cols)
      dists[start_idx] = 0

      queue.insert 0, start_idx
      steps = 0

      until queue.empty?
        prev_cost, prev_idx = queue.extract
        px, py = from_idx(prev_idx, cols)

        map.exits(px, py).each do |dx, dy|
          new_idx = to_idx(px + dx, py + dy, cols)
          cost = prev_cost + 1

          if !dists.include?(new_idx) || cost < dists[new_idx]
            dists[new_idx] = cost
            prevs[new_idx] = prev_idx

            queue.insert(cost, new_idx)
          end
        end

        steps += 1
        if steps % 200 == 0
          args.state.dijkstra = [dists, prevs]
          Fiber.yield
        end
      end

      args.state.dijkstra = [dists, prevs]
    end

    def a_star(args, start, goal, map)
      cols = map.width
      goal_idx = to_idx(goal.x, goal.y, cols)

      open = MinHeap.new
      open.insert(0, to_idx(start.x, start.y, cols))
      prevs = {}
      dists = { to_idx(start.x, start.y, cols) => 0 }

      until open.empty?
        _cost, idx = open.extract
        return [dists, prevs] if idx == goal_idx

        px, py = from_idx(idx, cols)

        map.exits(px, py).each do |dx, dy|
          next_idx = to_idx(px + dx, py + dy, cols)
          next_cost = dists[idx] + 1 # support alternate movementcost(current, neighbor)

          if !dists.include?(next_idx) || next_cost < dists[next_idx]
            # Hack for more "diagonal" paths
            # This creates a checkerboard of (slight) directional preferences, so the shortest path will prefer to alternate directions
            nudge = 0
            nudge = 1 if (px + py) % 2 == 0 and dx == 0
            nudge = 1 if (px + py) % 2 == 1 and dy == 0

            dists[next_idx] = next_cost
            priority = next_cost + 1.001 * dist_manhattan([px + dx, py + dy], goal) + 0.001 * nudge
            open.insert(priority, next_idx)
            prevs[next_idx] = idx
          end
        end
      end

      [dists, prevs]
    end

    # prevs should be the result of a previous dijkstra call or another similar method that returns an array of steps from [start_x, start_y]
    # returns a list of cells on the path, including the start and end
    # returns nil if there is no path
    def reconstruct_path(prevs, start, goal, cols)
      path = []

      start_idx = to_idx(start.x, start.y, cols)
      prev_idx = to_idx(goal.x, goal.y, cols)

      until prev_idx == start_idx
        path << from_idx(prev_idx, cols)
        prev_idx = prevs[prev_idx]
      end

      path.reverse
    end
  end
end
