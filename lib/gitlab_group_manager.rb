# frozen_string_literal: true

require 'gitlab'

# Better docs for GGM module TODO
module GGM
  def self.gitlab_client
    @gitlab_client ||= Gitlab.client(endpoint: ENV['CI_API_V4_URL'], private_token: ENV['GITLAB_TOKEN'])
  end

  def self.dry_run
    @dry_run ||= Env['DRY_RUN']
  end

  # Better docs for Env TODO
  class Env
    TRUTHY_VALUES = %w[t true yes y 1].freeze
    FALSEY_VALUES = %w[f false n no 0].freeze

    attr_reader :value

    def self.[](name)
      @env ||= {}
      @env[name] ||= Env.new(name).value
    end

    def initialize(name)
      @value = ENV[name].to_s.downcase
      @value = true if TRUTHY_VALUES.include?(@value.to_s)
      @value = false if FALSEY_VALUES.include?(@value.to_s)
    end
  end
end

require_relative 'ggm/file'
require_relative 'ggm/config_parser'
require_relative 'ggm/project_set'
