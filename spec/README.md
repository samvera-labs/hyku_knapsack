# Knapsack View Path Configuration

This directory contains the test configuration for the HykuKnapsack gem, including a fix for view path prioritization in the test environment.

## View Path Priority Issue

In the test environment, knapsack views were not being properly prioritized over hyrax-webapp views. This caused view specs to render hyrax-webapp views instead of the knapsack overlay views.

## The Fix

### 1. Automatic Configuration (`rails_helper.rb`)

The `rails_helper.rb` file now includes a `before(:suite)` hook that automatically ensures knapsack view paths are prioritized:

```ruby
config.before(:suite) do
  # Ensure knapsack view paths are properly configured
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
```

### 2. Helper Methods (`spec/support/knapsack_view_path_helper.rb`)

For individual view specs that need explicit control, helper methods are available:

- `ensure_knapsack_view_paths` - Ensures knapsack view paths are prioritized
- `debug_view_paths` - Outputs view path information for debugging

### 3. Test Coverage (`spec/views/view_path_priority_spec.rb`)

A test suite verifies that the view path configuration works correctly.

## Usage

### Automatic (Recommended)

The fix is applied automatically when running any view specs. No additional configuration is needed.

### Manual (For Complex Cases)

If you need explicit control in a specific view spec:

```ruby
RSpec.describe 'My View', type: :view do
  before do
    ensure_knapsack_view_paths
  end
  
  it 'renders the knapsack version' do
    # Your view spec here
  end
end
```

### Debugging

To debug view path issues:

```ruby
RSpec.describe 'My View', type: :view do
  it 'shows view path information' do
    debug_view_paths
    # This will output the view paths in order
  end
end
```

## What This Fixes

- ✅ Knapsack views are prioritized over hyrax-webapp views in test environment
- ✅ View specs render the correct knapsack overlay views
- ✅ No more falling back to hyrax-webapp views when knapsack views exist
- ✅ Consistent behavior between development and test environments