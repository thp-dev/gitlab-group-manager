# frozen_string_literal: true

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

def run_ggm
  Dir.chdir('/tmp') { puts `'ggm'` }
end

def delete_projects(projects)
  projects.each do |project|
    Gitlab.delete_project(project.id)
  end
  wait_for_projects_to_be_deleted(projects)
end

def wait_for_projects_to_be_deleted(projects)
  while projects.length.positive?
    projects.each do |project|
      Gitlab.project(project.id)
    rescue StandardError
      projects.delete(project)
    end
    sleep 1
  end
end
