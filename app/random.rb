# frozen_string_literal: true

# Generate random numbers that are in a range
def rand_range(range)
  raise 'Argument should be a range' unless range.is_a? Range

  rand(range.size) + range.begin
end

# Generate normally distributed random numbers via the Box-Muller transform
def rand_normal(mean, variance)
  u1 = 1 - rand
  u2 = 1 - rand
  std_normal = Math.sqrt(-2 * Math.log(u1)) * Math.sin(2 * Math::PI * u2)

  mean + Math.sqrt(variance) * std_normal
end
