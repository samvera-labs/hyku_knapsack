# frozen_string_literal: true

namespace :hyku_knapsack do
  namespace :i18n do
    desc 'Translate missing locale keys from English to all other languages'
    task translate_missing: :environment do
      hyku_i18n_config_path = '/app/samvera/hyrax-webapp/config/i18n-tasks.yml'

      sh "cd /app/samvera && bundle exec i18n-tasks translate-missing --config #{hyku_i18n_config_path} --from en de es fr it pt-BR zh"
    end
  end
end
