# frozen_string_literal: true

$debug = { show_mapgen: false, reveal_map: false }

require 'app/data_struct/heap.rb'

require 'app/benchmark.rb'
require 'app/process.rb'
require 'app/random.rb'
require 'app/grid.rb'

Rect = Struct.new(:x, :y, :w, :h) do
  def center
    [x + w.idiv(2), y + h.idiv(2)]
  end

  def sample
    a = rand_range(x...(x + w))
    b = rand_range(y...(y + h))
    [a, b]
  end
end

Color = Struct.new(:r, :g, :b)

require 'app/mapgen/map_helpers.rb'
require 'app/mapgen/player_spawn.rb'
require 'app/mapgen/ca_map.rb'
require 'app/mapgen/map_culler.rb'
require 'app/mapgen/min_span_tree.rb'
require 'app/mapgen/simple_hallways.rb'
require 'app/mapgen/random_tiles.rb'
require 'app/mapgen/simple_rooms.rb'

require 'app/sprite_lookup.rb'

require 'app/pathfinding.rb'

require 'app/fov.rb'

REPEAT_DELAY_FRAMES = 4

def tick(args)
  initialize(args)

  if args.state.key_delay.positive?
    args.state.key_delay -= 1
  else
    args.state.player_x = args.state.next_player_x
    args.state.player_y = args.state.next_player_y
    handle_input(args)
  end

  run_procs(args) unless args.state.procs.empty?

  draw(args)

  output_benchmarks(args)
  args.outputs.debug << args.gtk.framerate_diagnostics_primitives
end

def run_procs(args)
  # TODO: this needs to handle job scheduling, otherwise a tick can become arbitrarily slow
  # also under the current system, each step takes at least a tick, even if it finishes faster
  args.state.procs.each do |_, chain|
    chain.current += 1 unless chain.steps[chain.current].fiber.alive?

    if chain.current >= chain.steps.length
      chain.done = true
    else
      chain.steps[chain.current].run(args)
    end
  end

  args.state.procs.reject! { |_, chain| chain.done }
end

def process_chain(constructors)
  {
    current: 0,
    done: false,
    steps: constructors.map(&:generate)
  }
end

def map_gen_chain
  [].tap do |chain|
    chain << RandomTiles.new([10, 10, 80, 50], 0.35)
    chain << CaMap.new([0b1_0011_0001, 0b1_1111_0000], 0.9, 5)
    chain << MapCuller.new(6, MapCuller::ROOM_OP[:overwrite])
    chain << SimpleRooms.new(10..10, 3..8, 3..8)
    chain << MinSpanTree.new
    chain << SimpleHallways.new
    chain << PlayerSpawn.new
  end
end

def initialize(args)
  # args.outputs.background_color = [0, 0, 0]

  args.state.mapgen ||= map_gen_chain
  # args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.procs ||= { mapgen: process_chain(args.state.mapgen) }

  args.state.player_x ||= 0
  args.state.player_y ||= 0
  args.state.next_player_x ||= 0
  args.state.next_player_y ||= 0
  args.state.key_delay ||= REPEAT_DELAY_FRAMES
  args.state.dijkstra ||= []
  args.state.fov ||= []
  args.state.fov_debug ||= false
end

def handle_input(args)
  new_player_x = args.state.player_x
  new_player_y = args.state.player_y

  if args.inputs.up
    new_player_y += 1
    args.state.key_delay = REPEAT_DELAY_FRAMES
  elsif args.inputs.down
    new_player_y -= 1
    args.state.key_delay = REPEAT_DELAY_FRAMES
  elsif args.inputs.right
    new_player_x += 1
    args.state.key_delay = REPEAT_DELAY_FRAMES
  elsif args.inputs.left
    new_player_x -= 1
    args.state.key_delay = REPEAT_DELAY_FRAMES
  end

  try_move(args, new_player_x, new_player_y)

  args.state.procs[:mapgen] = process_chain(args.state.mapgen) if args.inputs.keyboard.key_down.r
  args.state.fov_debug = !args.state.fov_debug if args.inputs.keyboard.key_down.q
end

def try_move(args, new_x, new_y)
  return unless args.state.grid.present?(new_x, new_y) && (new_x != args.state.player_x || new_y != args.state.player_y)

  args.state.next_player_x = new_x
  args.state.next_player_y = new_y
  args.state.procs[:dijkstra] = process_chain([Pathfinding::Dijkstra])
  args.state.fov = Fov.visible_in_range(args.state.grid, [new_x, new_y], 10)
  Fov.render(args)
end

def draw(args)
  grid = args.state.grid

  args.outputs.labels << [800, 680, "You are at #{args.state.player_x}, #{args.state.player_y} and the grid is #{grid[args.state.player_x, args.state.player_y]}"]

  screen_w = grid.tile_size * grid.width
  screen_h = grid.tile_size * grid.height

  args.outputs.borders << {
    x: grid.x,
    y: grid.y,
    w: screen_w,
    h: screen_h,
    r: 255,
    g: 255,
    b: 255
  }

  # statics
  # args.outputs.sprites << {
  #   x: grid.x,
  #   y: grid.y,
  #   w: screen_w,
  #   h: screen_h,
  #   path: :bg_map,
  #   source_x: 0,
  #   source_y: 0,
  #   source_w: grid.tile_size * grid.width,
  #   source_h: grid.tile_size * grid.height,
  # }

  # fractional camera motion
  spline = [
    [0.0, 0.75, 0.85, 1.0]
  ]
  frac = args.easing.ease_spline (args.tick_count - REPEAT_DELAY_FRAMES + args.state.key_delay), args.tick_count,
                                 REPEAT_DELAY_FRAMES, spline
  fractional_x = frac * (args.state.next_player_x - args.state.player_x)
  fractional_y = frac * (args.state.next_player_y - args.state.player_y)

  # merge fov and map
  args.outputs[:fov_map].sprites << {
    x: 0, y: 0, w: screen_w, h: screen_h,
    source_w: screen_w, source_h: screen_h,
    path: :fov
  }
  args.outputs[:fov_map].sprites << {
    x: 0, y: 0, w: screen_w, h: screen_h,
    source_w: screen_w, source_h: screen_h,
    path: :map,
    blendmode_enum: 4
  }
  args.outputs.sprites << {
    x: grid.x, y: grid.y, w: screen_w, h: screen_h,
    source_w: screen_w, source_h: screen_h,
    path: :fov_map
  }

  args.outputs.sprites << {
    x: grid.x, y: grid.y, w: screen_w, h: screen_h,
    source_w: screen_w, source_h: screen_h,
    path: :tmp
  } if args.state.fov_debug

  # player
  args.outputs.sprites << tile_extended(
    (args.state.player_x + fractional_x) * grid.tile_size + grid.x,
    (args.state.player_y + fractional_y) * grid.tile_size + grid.y,
    grid.tile_size,
    grid.tile_size,
    25,
    175,
    25,
    255,
    '@'
  )

  # cursor
  args.state.mp ||= [0, 0]
  args.state.last_mp ||= [0, 0]
  args.state.last_mp = args.state.mp
  mp = mouse_pos(args)
  args.state.mp = mp

  unless mp.nil?
    args.outputs.solids << [mp.x * grid.tile_size + grid.x, mp.y * grid.tile_size + grid.y, 12, 12]
    args.outputs.labels << [800, 660, "The mouse is at #{mp.x}, #{mp.y} with #{args.state.dijkstra[0][mp.y * 80 + mp.x]}"] unless args.state.dijkstra[0].nil?

    if mp != args.state.last_mp && grid.present?(mp.x, mp.y)
      astar = Pathfinding.a_star(args, [args.state.player_x, args.state.player_y], mp, args.state.grid)
      astar[1].each do |k, v|
        px, py = [k % 80, k.idiv(80)]

        args.outputs[:path].solids << {
          x: px * grid.tile_size,
          y: py * grid.tile_size,
          w: grid.tile_size,
          h: grid.tile_size,
          r: 255,
          g: 5,
          b: 5,
          a: 120
        }
      end

      Pathfinding.reconstruct_path(astar[1], [args.state.player_x, args.state.player_y], mp, args.state.grid.width).each do |path_x, path_y|
        args.outputs[:path].solids << {
          x: path_x * grid.tile_size,
          y: path_y * grid.tile_size,
          w: grid.tile_size,
          h: grid.tile_size,
          r: 255,
          g: 255,
          b: 255,
          a: 120
        }
      end
    end

    args.outputs.sprites << {
      x: grid.x,
      y: grid.y,
      w: screen_w,
      h: screen_h,
      path: :path,
      source_x: 0,
      source_y: 0,
      source_w: grid.tile_size * grid.width,
      source_h: grid.tile_size * grid.height,
    } if grid.present?(mp.x, mp.y)
  end
end

# Convert the mouse position to a tile on the grid if its in bounds
def mouse_pos(args)
  grid = args.state.grid
  mouse_x = args.inputs.mouse.x
  mouse_x = ((mouse_x - grid.x) / grid.tile_size - 0.5).round
  mouse_y = args.inputs.mouse.y
  mouse_y = ((mouse_y - grid.y) / grid.tile_size - 0.5).round

  [mouse_x, mouse_y] if grid.in_bounds(mouse_x, mouse_y)
end
