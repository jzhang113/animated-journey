require 'app/grid.rb'

REPEAT_DELAY_FRAMES = 4

def tick(args)
  initialize(args)

  if args.state.key_delay > 0
    args.state.key_delay -= 1
  else
    args.state.player_x = args.state.next_player_x
    args.state.player_y = args.state.next_player_y
    handle_input(args)
  end

  draw(args)
end

def initialize(args)
  args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.grid[1, 2] = 1
  args.state.grid[2, 3] = 1
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
end

def draw(args)
  grid = args.state.grid

  args.outputs.labels  << [10, 680, "Hello player, you are at #{args.state.player_x}, #{args.state.player_y}"]
  args.outputs.labels  << [10, 700, "frames: #{args.gtk.current_framerate.round }"]

  args.outputs.borders << {
    x: grid.x,
    y: grid.y,
    w: grid.tile_size * 80,
    h: grid.tile_size * 50,
  }

  # statics
  grid.each_with_index do |row_arr, row|
    row_arr.each_with_index do |tile, col|
      args.outputs.solids << {
        x: col * grid.tile_size + grid.x,
        y: row * grid.tile_size + grid.y,
        w: grid.tile_size,
        h: grid.tile_size,
        r: 200
      } if tile == 1
    end
  end

  # player
  spline = [
    [0.0, 0.75, 0.85, 1.0]
  ]
  frac = args.easing.ease_spline (args.tick_count - REPEAT_DELAY_FRAMES + args.state.key_delay), args.tick_count, REPEAT_DELAY_FRAMES, spline
  fractional_x = frac * (args.state.next_player_x - args.state.player_x)
  fractional_y = frac * (args.state.next_player_y - args.state.player_y)
  putz "#{args.state.key_delay} #{fractional_x} #{fractional_y}"

  args.outputs.solids << {
    x: (args.state.player_x + fractional_x) * grid.tile_size + grid.x,
    y: (args.state.player_y + fractional_y) * grid.tile_size + grid.y,
    w: grid.tile_size,
    h: grid.tile_size,
  }
end
