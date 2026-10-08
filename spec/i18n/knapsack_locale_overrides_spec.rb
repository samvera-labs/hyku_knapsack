# frozen_string_literal: true

require 'rails_helper'

# The knapsack's locale files override Hyku's and Hyrax's text. That only works while the
# knapsack's files load last, and a Hyku change can quietly reorder them (samvera/hyku#3325
# did, see notch8/palni_palci_knapsack#788). This checks every string the knapsack defines still
# wins, so a Hyku bump that breaks the order fails here instead of on staging.
RSpec.describe 'knapsack locale overrides' do
  def leaves(tree, prefix = [])
    tree.flat_map do |key, value|
      value.is_a?(Hash) ? leaves(value, prefix + [key]) : [[(prefix + [key]).join('.'), value]]
    end
  end

  it 'resolve to the knapsack text' do
    expected = {}
    HykuKnapsack::Engine.root.glob('config/locales/**/*.yml').sort.each do |file|
      YAML.load_file(file).each do |locale, tree|
        next unless tree.is_a?(Hash)
        leaves(tree).each do |key, value|
          expected[[locale, key]] = value if value.is_a?(String)
        end
      end
    end

    lost = expected.filter_map do |(locale, key), value|
      actual = I18n.t(key, locale:, default: nil)
      "#{locale}.#{key}: expected #{value.inspect}, got #{actual.inspect}" unless actual == value
    end

    skip 'this knapsack has no locale files yet' if expected.empty?
    expect(lost).to be_empty, "#{lost.size} of #{expected.size} knapsack strings lost to another locale file:\n#{lost.first(25).join("\n")}"
  end
end
