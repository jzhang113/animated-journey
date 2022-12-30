require 'app/grid.rb'

def tick(args)
  initialize(args)
  handle_input(args)
  draw(args)
end

def initialize(args)
  args.state.grid ||= Grid.new(10, 10, 80, 50)
  args.state.grid[1, 2] = 1
  args.state.player_x ||= 0
  args.state.player_y ||= 0
end

def handle_input(args)
  new_player_x = args.state.player_x
  new_player_y = args.state.player_y

  if args.inputs.up
    new_player_y += 1
  elsif args.inputs.down
    new_player_y -= 1
  elsif args.inputs.right
    new_player_x += 1
  elsif args.inputs.left
    new_player_x -= 1
  end

  args.state.player_x = new_player_x if new_player_x >= 0 && new_player_x < args.state.grid.width
  args.state.player_y = new_player_y if new_player_y >= 0 && new_player_y < args.state.grid.height
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

  grid.each_with_index do |row_arr, row|
    row_arr.each_with_index do |tile, col|
      args.outputs.solids << {
        x: col * grid.tile_size + grid.x,
        y: row * grid.tile_size + grid.y,
        w: grid.tile_size,
        h: grid.tile_size,
      } if args.state.player_x == col && args.state.player_y == row

      args.outputs.solids << {
        x: col * grid.tile_size + grid.x,
        y: row * grid.tile_size + grid.y,
        w: grid.tile_size,
        h: grid.tile_size,
        r: 200
      } if tile == 1
    end
  end
end
