# frozen_string_literal: true

require 'app/benchmark.rb'
require 'app/process.rb'
require 'app/random.rb'
require 'app/grid.rb'

Rect = Struct.new(:x, :y, :w, :h) do
  def center
    [x + w.idiv(2), y + h.idiv(2)]
  end
end

Color = Struct.new(:r, :g, :b)

require 'app/mapgen/map_helpers.rb'
require 'app/mapgen/player_spawn.rb'
require 'app/mapgen/ca_map.rb'

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
    chain << CaMap.new(Rect.new(10, 10, 80, 50), [0b1_0011_0001, 0b1_1111_0000], 0.15, 0.85, 5)
    chain << PlayerSpawn.new
  end
end

def initialize(args)
  args.state.mapgen ||= map_gen_chain
  # args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.procs ||= [process_chain(args.state.mapgen)]
  args.state.player_x ||= 0
  args.state.player_y ||= 0
  args.state.next_player_x ||= 0
  args.state.next_player_y ||= 0
  args.state.key_delay ||= REPEAT_DELAY_FRAMES
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
  args.state.next_player_x = new_x if args.state.grid.present?(new_x, new_y)
  args.state.next_player_y = new_y if args.state.grid.present?(new_x, new_y)
end

def draw(args)
  grid = args.state.grid

  args.outputs.labels  << [800, 680, "You are at #{args.state.player_x}, #{args.state.player_y} and the grid is #{grid[args.state.player_x, args.state.player_y]}"]

  args.outputs.borders << {
    x: grid.x,
    y: grid.y,
    w: grid.tile_size * grid.width,
    h: grid.tile_size * grid.height
  }

  # statics
  grid.each_with_index do |row_arr, row|
    row_arr.each_with_index do |tile, col|
      next if tile.nil?

      args.outputs.solids << {
        x: col * grid.tile_size + grid.x,
        y: row * grid.tile_size + grid.y,
        w: grid.tile_size,
        h: grid.tile_size,
        r: tile == 2 ? 200 : 0,
        g: tile == 3 ? 200 : 0,
        b: tile == 1 ? 200 : 0
      }
    end
  end

  # player
  spline = [
    [0.0, 0.75, 0.85, 1.0]
  ]
  frac = args.easing.ease_spline (args.tick_count - REPEAT_DELAY_FRAMES + args.state.key_delay), args.tick_count,
                                 REPEAT_DELAY_FRAMES, spline
  fractional_x = frac * (args.state.next_player_x - args.state.player_x)
  fractional_y = frac * (args.state.next_player_y - args.state.player_y)
  # putz "#{args.state.key_delay} #{fractional_x} #{fractional_y}"

  args.outputs.solids << {
    x: (args.state.player_x + fractional_x) * grid.tile_size + grid.x,
    y: (args.state.player_y + fractional_y) * grid.tile_size + grid.y,
    w: grid.tile_size,
    h: grid.tile_size
  }
end
