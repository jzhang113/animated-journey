# frozen_string_literal: true

$benchmarks = {}
BENCH_OUTPUT_INTERVAL = 60

def benchmark(key)
  start = Time.now
  yield
  fin = Time.now

  $benchmarks[key] ||= []
  $benchmarks[key] << fin - start
end

def xbenchmark(_key)
  yield
end

def output_benchmarks(args)
  return unless $benchmarks.any?
  return unless args.tick_count % BENCH_OUTPUT_INTERVAL == 0

  benches = $benchmarks.each do |k, v|
    $benchmarks[k] = v.sum / v.size * 1000
  end

  benches = benches.reject { |_, v| v <= 0.01 }
  return if benches.empty?

  benches = benches.sort_by { |_, v| -v }
              .map { |k, v| "#{k}: #{v.round(4)}" }

  args.gtk.append_file('benchmarks.txt', "#{benches.join(', ')}\n")
  $benchmarks = {}
end
