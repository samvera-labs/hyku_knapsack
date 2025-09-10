# frozen_string_literal: true

# The main purpose of these overrides is to handle multiple authorities directories.
# Questioning Authority gem only allows one directory for local authorities, which by
# default is looking at the Hyku's `config/authorities directory` instead of Knapsack's
# `config/authorities` directory.
#
# We want have the ability to add HykuKnapsack's authorities directory in addition to
# Hyku's.  If two are of the same name, then the one in HykuKnapsack should override the
# one in Hyku.

HykuKnapsack::AUTHORITIES_PATH = File.join(HykuKnapsack::Engine.root, 'config', 'authorities')

module Qa
  module Authorities
    # OVERRIDE Questioning Authority v5.10.0 to load knapsack authorities
    # see: https://github.com/samvera/questioning_authority/blob/14d233a8404a8d805f1213ae9431ad4ff82a9937/lib/qa/authorities/local.rb
    module LocalDecorator
      # Overidding to handle to return an array of paths
      def subauthorities_path(knapsack_authorities_path: HykuKnapsack::AUTHORITIES_PATH)
        # knapsack_authorities_path should be first to allow for overriding in case of duplicate names
        authorities_paths = [knapsack_authorities_path, config[:local_path]]

        authorities_paths.map do |path|
          path if File.directory?(path)
        end.compact
      end

      # Overriding to handle an array of paths to return names of all files
      def names
        paths = subauthorities_path # Assuming this now returns an array
        all_names = []

        paths.each do |path|
          unless Dir.exist? path
            raise Qa::ConfigDirectoryNotFound,
                  "There's no directory at #{path}. You must create it in order to use local authorities"
          end

          all_names += Dir.entries(path).map { |f| File.basename(f, '.yml') if /yml$/.match?(f) }.compact
        end

        all_names.uniq
      end
    end
  end
end

module Qa
  module Authorities
    module Local
      # OVERRIDE Questioning Authority v5.10.0 to return first file found from an array of paths
      # see: https://github.com/samvera/questioning_authority/blob/14d233a8404a8d805f1213ae9431ad4ff82a9937/lib/qa/authorities/local/file_based_authority.rb
      module FileBasedAuthorityDecorator
        def subauthority_filename
          subauthorities_paths = Local.subauthorities_path

          subauthorities_paths.each do |path|
            yaml_file = File.join(path, "#{subauthority}.yml")
            return yaml_file if File.exist?(yaml_file)
          end
        end
      end
    end
  end
end

Qa::Authorities::Local.singleton_class.send(:prepend, Qa::Authorities::LocalDecorator)
Qa::Authorities::Local::FileBasedAuthority.prepend(Qa::Authorities::Local::FileBasedAuthorityDecorator)
