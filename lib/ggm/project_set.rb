# frozen_string_literal: true

module GGM
  # Better docs for ProjectSet TODO
  class ProjectSet
    attr_reader :projects

    def initialize(project_array)
      validate_projects!(project_array)
      @projects = project_array
    end

    def validate_projects!(project_array)
      raise 'Not an array' unless project_array.is_a?(Array)

      raise 'Empty array' unless project_array.count.positive?

      project_array.each do |project|
        %w[id name].each do |method|
          raise "Invalid project: missing #{method}" unless project.respond_to?(method)
        end
      end
    end
  end
end
