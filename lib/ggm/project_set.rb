# frozen_string_literal: true

module GGM
  # Better docs for ProjectSet TODO
  class ProjectSet
    attr_reader :projects

    def initialize(project_array)
      validate_projects!(project_array)
      @projects = project_array
    end

    def ensure_file(file)
      @projects.each do |project|
        in_project = file.exists_and_matches?(project)
        add_file_to_project(file, project) unless in_project

        puts "#{file} already up to date in #{project.name}" if in_project
      end
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

    private

    def dry_runnable(output)
      yield unless GGM.dry_run

      puts "#{GGM.dry_run ? 'DRY RUN: ' : ''}#{output}"
    end

    def add_file_to_project(file, project, branch: 'master')
      on_unprotected_branch(project, branch) do
        create_or_update_file_in_project(project, branch, file)
      end
    end

    def create_or_update_file_in_project(project, branch, file)
      if file.exists?(project, branch: branch)
        file_commit(project, branch, file, 'update')
      else
        file_commit(project, branch, file, 'create')
      end
    end

    def file_commit(project, branch, file, action)
      commit_message_prefix = file.options[:commit_prefix]
      commit_message_suffix = file.options[:commit_suffix]
      message = "#{commit_message_prefix}#{action.capitalize}d file: #{file.location}#{commit_message_suffix}"
      dry_runnable("Add commit with message: #{message}") do
        GGM.gitlab_client.create_commit(project.id, branch, message,
                                        [{ action: action, file_path: file.location, content: file.content }])
      end
    end

    def on_unprotected_branch(project, branch)
      begin
        branch_state = branch_protection_state(project, branch)
        safe_unprotect(project, branch)
      rescue Gitlab::Error::NotFound
        puts "No branch protection found for #{project.name}"
      end
      yield
    ensure
      safe_protect(project, branch, branch_state)
    end

    def safe_unprotect(project, branch)
      dry_runnable("Unprotect #{branch} in #{project.name}") do
        GGM.gitlab_client.unprotect_branch(project.id, branch)
      end
    end

    def safe_protect(project, branch, branch_state)
      return unless branch_state

      dry_runnable("Re-protect #{branch} in #{project.name}") do
        GGM.gitlab_client.protect_branch(project.id, branch, branch_state)
      end
    end

    def branch_protection_state(project, branch)
      protected_branch_response = GGM.gitlab_client.protected_branch(project.id, branch).to_h
      protected_branch_response.slice(
        'push_access_levels',
        'merge_access_levels',
        'unprotect_access_levels',
        'code_owner_approval_required'
      )
    end
  end
end
