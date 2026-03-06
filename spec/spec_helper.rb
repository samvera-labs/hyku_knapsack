# frozen_string_literal: true

# Load hyrax-webapp's spec_helper for WebMock, rspec-its, Valkyrie adapter registration,
# and shared RSpec configuration. Rails must already be booted before this is required
# (see rails_helper.rb which boots Rails first, then requires spec_helper).
require File.expand_path("../hyrax-webapp/spec/spec_helper.rb", __dir__)
