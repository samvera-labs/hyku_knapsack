# frozen_string_literal: true

module KnapsackViewPathHelper
  # Ensure knapsack view paths are prioritized
  # This helper can be used in individual view specs to ensure proper view path configuration
  def ensure_knapsack_view_paths
    if defined?(ApplicationController)
      ([ApplicationController] + ApplicationController.descendants).each do |klass|
        paths = klass.view_paths.collect(&:to_s)
        knapsack_view_path = HykuKnapsack::Engine.root.join('app', 'views').to_s
        
        # Only prepend if knapsack view path is not already first
        unless paths.first == knapsack_view_path
          paths = [knapsack_view_path] + paths
          klass.view_paths = paths.uniq
        end
      end
    end
  end

  # Debug view path information
  # Useful for troubleshooting view path issues
  def debug_view_paths
    view_paths = ApplicationController.view_paths.collect(&:to_s)
    knapsack_view_path = HykuKnapsack::Engine.root.join('app', 'views').to_s
    
    puts "View paths in order:"
    view_paths.each_with_index do |path, index|
      marker = path == knapsack_view_path ? " <-- KNAPSACK" : ""
      puts "  #{index}: #{path}#{marker}"
    end
    
    puts "Knapsack view path: #{knapsack_view_path}"
    puts "Knapsack path is first: #{view_paths.first == knapsack_view_path}"
  end
end

RSpec.configure do |config|
  config.include KnapsackViewPathHelper, type: :view
end