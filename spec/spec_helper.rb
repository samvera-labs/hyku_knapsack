# frozen_string_literal: true

RSpec.configure do |config|
  # Look for an overriding spec file and skip if it exists
  config.around do |example|
    if example.file_path.starts_with?("./spec/hyku_specs") && File.exist?(example.file_path.sub("./spec/hyku_specs", "."))
      skip "Override exists of this test file in engine."
    else
      example.run
    end
  end
end

require File.expand_path("hyku_specs/rails_helper.rb", __dir__)
require File.expand_path("hyku_specs/spec_helper.rb", __dir__)
