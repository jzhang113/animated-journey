# frozen_string_literal: true

class MinSpanTree
  include MapHelpers

  def initialize; end

  def generate
    fiber = Fiber.new do |args|
      run(args)
    end

    Process.new(fiber)
  end

  def run(args)
    args.state.room_points = args.state.rooms.map(&:sample)
    args.state.adjacency = calc_adjacency(args.state.room_points)
    Fiber.yield

    args.state.connections = prim(args.state.rooms.length, args.state.adjacency)
  end

  # Calculate a full adjacency matrix between a list of points
  def calc_adjacency(points)
    adj = Array.new(points.length) { Array.new(points.length) }

    points.each_with_index do |p1, i|
      points.each_with_index do |p2, j|
        next if i < j

        dist = dist_euclidean(p1, p2)
        adj[i][j] = dist
        adj[j][i] = dist
      end
    end

    adj
  end

  # Calculate a MST from a complete graph
  def prim(n, adjacency)
    # Choose start vertex u
    u = 0
    priorities = []
    parents = []
    mst = []

    # Initialize all other vertices
    n.times do |v|
      priorities[v] = adjacency[v][u]
      parents[v] = u
    end

    # Construct n - 1 edges (since its a MST)
    (n - 1).times do
      min = 1_000_000
      min_v = nil

      # Find the lowest priority vertex
      n.times do |v|
        if priorities[v] > 0 && priorities[v] < min
          min = priorities[v]
          min_v = v
        end
      end

      # Update the MST
      priorities[min_v] = 0
      mst << [min_v, parents[min_v]]

      # Update the remaining priorities
      n.times do |v|
        if priorities[v] > adjacency[v][min_v]
          priorities[v] = adjacency[v][min_v]
          parents[v] = min_v
        end
      end
    end

    mst
  end
end
