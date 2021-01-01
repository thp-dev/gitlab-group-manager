# frozen_string_literal: true

require 'yaml'

module GGM
  class ConfigError < StandardError
  end

  # Reads the yaml config that GGM uses to understand what to do
  # TODO: better docs
  class ConfigParser
    attr_reader :config, :project_set_configs

    def initialize(config_file_path: '.ggm.yaml')
      @config = YAML.load_file(config_file_path)
      @project_set_configs = build_project_config_tuple
    end

    def apply
      @project_set_configs.each do |project_set, config|
        config['files'].each do |file_config|
          file = GGM::File.new(file_config['path'])
          project_set.ensure_file(file)
        end
      end
    end

    private

    def build_project_config_tuple
      raise GGM::ConfigError, 'Missing "groups" section' unless @config['groups']

      @config['groups'].map do |group_config|
        group = validate_group(group_config['name'])
        projects = GGM.gitlab_client.group_projects(group.id, project_selection_options(group_config))
                      .auto_paginate.sort_by(&:name)
        config_to_apply = group_config.slice('files')
        [ProjectSet.new(projects), config_to_apply]
      end
    end

    def project_selection_options(group_config)
      {
        include_subgroups: group_config['include_subgroups'] || false,
        archived: group_config['archived'] || false
      }
    end

    def validate_group(name)
      raise GGM::ConfigError, 'Missing group name' unless name

      groups = available_groups
      group = groups.find { |g| g.name == name }
      raise GGM::ConfigError, "Could not find group: #{name}. Did you mean: #{groups.map(&:name)} ?" unless group

      group
    end

    def available_groups
      groups = GGM.gitlab_client.groups.auto_paginate
      unless groups&.count&.positive?
        raise GGM::ConfigError, "#{GGM.gitlab_client.user.username} cannot access any groups"
      end

      groups
    end
  end
end
