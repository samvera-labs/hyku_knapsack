# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in hyku-knapsack.gemspec.
gemspec

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

gemfile_path = File.expand_path("hyrax-webapp/Gemfile", __dir__)
if File.exist?(gemfile_path)
  gemfile = File.read(gemfile_path).split("\n").reject { |l| l.match('knapsack') }
  # rubocop:disable Security/Eval
  eval(gemfile.join("\n"), binding)
  # rubocop:enable Security/Eval
end
