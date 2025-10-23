# frozen_string_literal: true

# Test to verify that knapsack view paths are properly prioritized in the test environment
RSpec.describe 'Knapsack View Path Priority', type: :view do
  it 'should prioritize knapsack views over hyrax-webapp views' do
    # Get the current view paths
    view_paths = controller.view_paths.collect(&:to_s)
    
    # Find the knapsack view path
    knapsack_view_path = HykuKnapsack::Engine.root.join('app', 'views').to_s
    hyrax_view_path = Rails.root.join('app', 'views').to_s
    
    puts "Knapsack view path: #{knapsack_view_path}"
    puts "Hyrax view path: #{hyrax_view_path}"
    puts "All view paths: #{view_paths}"
    
    # Knapsack view path should be first (highest priority)
    expect(view_paths.first).to eq(knapsack_view_path)
    
    # Hyrax view path should be later in the list
    expect(view_paths).to include(hyrax_view_path)
    expect(view_paths.index(knapsack_view_path)).to be < view_paths.index(hyrax_view_path)
  end
  
  it 'should be able to find knapsack views' do
    # Test that we can find a view in the knapsack
    knapsack_view_path = HykuKnapsack::Engine.root.join('app', 'views')
    
    # Check if the knapsack views directory exists
    expect(File.directory?(knapsack_view_path)).to be true
    
    # List some files in the knapsack views directory
    view_files = Dir.glob(File.join(knapsack_view_path, '**', '*.erb'))
    puts "Knapsack view files found: #{view_files.first(5)}"
    
    expect(view_files).not_to be_empty
  end

  it 'should use the knapsack view path helper' do
    # Test that the helper methods are available
    expect(self).to respond_to(:ensure_knapsack_view_paths)
    expect(self).to respond_to(:debug_view_paths)
    
    # Test that the helper works
    ensure_knapsack_view_paths
    
    # Verify the view paths are still correct after using the helper
    view_paths = controller.view_paths.collect(&:to_s)
    knapsack_view_path = HykuKnapsack::Engine.root.join('app', 'views').to_s
    
    expect(view_paths.first).to eq(knapsack_view_path)
  end
end