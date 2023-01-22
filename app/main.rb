# frozen_string_literal: true

require 'app/process.rb'
require 'app/random.rb'
require 'app/grid.rb'

REPEAT_DELAY_FRAMES = 4

def map_gen
  fiber = Fiber.new do
    Grid.new(10, 10, 80, 50).tap do |map|
      5.times do
        make_room map
        Fiber.yield map
      end
    end
  end

  callback = ->(args, result) { args.state.grid = result }
  Process.new(fiber, callback)
end

def make_room(map)
  w = rand_range(3..10)
  h = rand_range(3..10)
  x = rand(80 - w)
  y = rand(50 - h)

  w.times do |wx|
    h.times do |wh|
      map[x + wx, y + wh] = 1
    end
  end
end

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

  args.outputs.debug << args.gtk.framerate_diagnostics_primitives
end

def run_procs(args)
  args.state.procs.each { |p| p.run(args) }
  args.state.procs.keep_if { |p| p.fiber.alive? }
end

def initialize(args)
  args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.procs ||= [map_gen]
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

  args.state.next_player_x = new_player_x if new_player_x >= 0 && new_player_x < args.state.grid.width
  args.state.next_player_y = new_player_y if new_player_y >= 0 && new_player_y < args.state.grid.height

  args.state.procs << map_gen if args.inputs.keyboard.key_down.r
end

def draw(args)
  grid = args.state.grid

  args.outputs.labels  << [10, 680, "You are at #{args.state.player_x}, #{args.state.player_y}"]

  args.outputs.borders << {
    x: grid.x,
    y: grid.y,
    w: grid.tile_size * grid.width,
    h: grid.tile_size * grid.height
  }

  # statics
  grid.each_with_index do |row_arr, row|
    row_arr.each_with_index do |tile, col|
      next unless tile == 1

      args.outputs.solids << {
        x: col * grid.tile_size + grid.x,
        y: row * grid.tile_size + grid.y,
        w: grid.tile_size,
        h: grid.tile_size,
        r: 200
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
