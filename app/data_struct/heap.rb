# frozen_string_literal: true

# Array-based min-heap
# Each element should have the form [priority, data]
class MinHeap
  def initialize
    @heap = []
  end

  # Add an item containing [priority, data] to the heap
  def insert(priority, data)
    @heap.push([priority, data])
    up_heap(@heap.length - 1)
  end

  # Pop the root of the heap (which has the smallest priority)
  def extract
    return nil if @heap.empty?

    root = @heap[0]

    if @heap.length > 1
      # Replace the root with the last element and down_heap to restore the heap property
      @heap[0] = @heap.pop
      down_heap(0)
    else
      @heap.pop
    end

    root
  end

  def empty?
    @heap.empty?
  end

  private

  # Swap a node up if it is smaller than its parent
  def up_heap(idx)
    # Stop if its the root
    until idx.zero?
      parent = (idx - 1) >> 1

      # If the parent is smaller than the node, the heap property is satisfied
      return if @heap[parent][0] < @heap[idx][0]

      # Otherwise, swap with the parent to restore the heap property and check again
      @heap[idx], @heap[parent] = @heap[parent], @heap[idx]
      idx = parent
    end
  end

  # Swap a node down if it is larger than its children
  def down_heap(idx)
    loop do
      left = 2 * idx + 1
      right = 2 * idx + 2
      smallest = idx

      smallest = left if left < @heap.length && @heap[left][0] < @heap[smallest][0]
      smallest = right if right < @heap.length && @heap[right][0] < @heap[smallest][0]

      # If the node is smaller than both its children, the heap property is satisfied
      return if smallest == idx

      # Otherwise, swap with the smaller child to restore the heap property and check again
      @heap[idx], @heap[smallest] = @heap[smallest], @heap[idx]
      idx = smallest
    end
  end
end
