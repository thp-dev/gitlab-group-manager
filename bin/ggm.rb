#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/gitlab_group_manager'

def main
  config = GGM::ConfigParser.new(config_file_path: GGM::Env['GGM_CONFIG_FILE' || '.ggm.yaml'])
  config.apply
end

main
