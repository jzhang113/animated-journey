# frozen_string_literal: true

$debug = false

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

require 'app/heap.rb'
require 'app/pathfinding.rb'
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
  args.state.procs.each do |chain|
    chain.current += 1 unless chain.steps[chain.current].fiber.alive?

    if chain.current >= chain.steps.length
      chain.done = true
    else
      chain.steps[chain.current].run(args)
    end
  end

  args.state.procs.reject!(&:done)
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
    chain << RandomTiles.new(Rect.new(10, 10, 80, 50), 0.35)
    chain << CaMap.new([0b1_0011_0001, 0b1_1111_0000], 0.9, 5)
    chain << MapCuller.new(6, MapCuller::ROOM_OP[:overwrite])
    chain << SimpleRooms.new(10..10, 3..8, 3..8)
    chain << MinSpanTree.new
    chain << Hallways.new
    chain << PlayerSpawn.new
  end
end

def initialize(args)
  args.outputs.background_color = [0, 0, 0]

  args.state.mapgen ||= map_gen_chain
  # args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.procs ||= [process_chain(args.state.mapgen)]
  args.state.player_x ||= 0
  args.state.player_y ||= 0
  args.state.next_player_x ||= 0
  args.state.next_player_y ||= 0
  args.state.key_delay ||= REPEAT_DELAY_FRAMES
  args.state.dijkstra ||= []
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

  args.state.procs = [process_chain(args.state.mapgen)] if args.inputs.keyboard.key_down.r
end

def try_move(args, new_x, new_y)
  return unless args.state.grid.present?(new_x, new_y) && new_x != args.state.grid.player_x && new_y != args.state.grid.player_y
  args.state.next_player_x = new_x
  args.state.next_player_y = new_y
  args.state.dijkstra = Pathfinding.dijkstra(args, args.state.player_x, args.state.player_y, args.state.grid)
end

def draw(args)
  grid = args.state.grid

  args.outputs.labels << [800, 680, "You are at #{args.state.player_x}, #{args.state.player_y} and the grid is #{grid[args.state.player_x, args.state.player_y]}", 255, 255, 255]

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

  args.outputs.sprites << {
    x: grid.x,
    y: grid.y,
    w: screen_w,
    h: screen_h,
    path: :map,
    source_x: 0,
    source_y: 0,
    source_w: grid.tile_size * grid.width,
    source_h: grid.tile_size * grid.height,
  }

  # player
  spline = [
    [0.0, 0.75, 0.85, 1.0]
  ]
  frac = args.easing.ease_spline (args.tick_count - REPEAT_DELAY_FRAMES + args.state.key_delay), args.tick_count,
                                 REPEAT_DELAY_FRAMES, spline
  fractional_x = frac * (args.state.next_player_x - args.state.player_x)
  fractional_y = frac * (args.state.next_player_y - args.state.player_y)
  # putz "#{args.state.key_delay} #{fractional_x} #{fractional_y}"

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
  mp = mouse_pos(args)
  unless mp.nil?
    args.outputs.solids << [mp.x * grid.tile_size + grid.x, mp.y * grid.tile_size + grid.y, 12, 12, 255, 255, 255]
    args.outputs.labels << [800, 660, "The tile is #{args.state.dijkstra[0][mp.y][mp.x]}", 255, 255, 255] unless args.state.dijkstra[0].nil?
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
