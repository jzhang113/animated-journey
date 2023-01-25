# frozen_string_literal: true

class PlayerSpawn
  def generate
    fiber = Fiber.new do |args|
      found = false
      iters = 0

      until found || iters > 100 do
        px = rand_range(0...80)
        py = rand_range(0...50)
        iters += 1

        next unless args.state.grid.present?(px, py)

        args.state.next_player_x = px
        args.state.next_player_y = py

        found = true
      end
    end

    Process.new(fiber)
  end
end
