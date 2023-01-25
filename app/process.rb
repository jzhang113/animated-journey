# frozen_string_literal: true

# A wrapper for fibers, useful for either long running calculations or handling animations
# Process takes two extra parameters, delay and callback
# If the delay is positive, the fiber will run once every n ticks, otherwise, it will run as much as possible within a
# frame (length defined by FRAME_MS_TIME)
# After run returns either a partial or full result, it will be passed to the callback along with the global args
# Note that a partial result of nil will not trigger the callback
class Process
  attr_reader :fiber, :delay

  FRAME_MS_TIME = 10

  def initialize(fiber, delay = 0)
    @fiber = fiber
    @delay = delay
  end

  def run(args)
    if @delay.positive?
      run_once(args, args.tick_count)
    else
      run_for_frametime(args, FRAME_MS_TIME)
    end
  end

  private

  def run_once(args, tick_count)
    @fiber.resume(args) if tick_count % @delay == 0
  end

  def run_for_frametime(args, ms)
    start_time = Time.now.to_f
    result = @fiber.resume(args) while @fiber.alive? && (Time.now.to_f - start_time) * 1000 < ms
    result
  end
end
