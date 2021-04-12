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
    rescue StandardError => e
      raise GGM::ConfigError, e
    end

    def apply
      @project_set_configs.each do |project_set, config|
        config.each_key do |config_key|
          configurable = configurable_for_config_key(config_key)
          configurable&.new&.configure(project_set, config[config_key])
        end
      end
    end

    private

    def configurable_for_config_key(config_key)
      class_name = config_key.split('_').map(&:capitalize).join
      Object.const_get("GGM::Configurable::#{class_name}")
    rescue NameError
      nil
    end

    def build_project_config_tuple
      raise GGM::ConfigError, 'Missing "groups" section' unless @config['groups']

      @config['groups'].map do |group_config|
        group, subgroups = groups_and_subgroups(group_config)
        projects = filter_subgroup_projects(subgroups, group_config)
        projects += GGM.gitlab_client.group_projects(group.id, project_selection_options(group_config))
                       .auto_paginate
        projects.sort_by!(&:name)
        [ProjectSet.new(projects), group_config]
      end
    end

    def groups_and_subgroups(group_config)
      group = validate_group(group_config['name'])
      subgroups = GGM.gitlab_client.group_subgroups(group.id).auto_paginate.sort_by(&:name)
      [group, subgroups]
    end

    def filter_subgroup_projects(subgroups, group_config)
      projects = []

      subgroups.each do |subgroup|
        next if excluded_subgroup?(subgroup, group_config)

        projects += GGM.gitlab_client
                       .group_projects(subgroup.id, project_selection_options(group_config))
                       .auto_paginate
      end

      projects
    end

    def excluded_subgroup?(subgroup, group_config)
      group_config['excluded_subgroups']&.each do |subgroup_regex|
        return true unless (subgroup.name =~ /#{subgroup_regex}/).nil?
      end
      false
    end

    def project_selection_options(group_config)
      {
        include_subgroups: false,
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
