# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
end

require_relative '../lib/gitlab_group_manager'

module GitlabMocks
  extend RSpec::SharedContext

  let(:mock_gitlab_client) { instance_double('gitlab_client') }
  let(:mock_gitlab_error_response) { instance_double('gitlab_error_response') }
  let(:mock_gitlab_request) { instance_double('gitlab_request') }
  let(:mock_groups_response) { instance_double('groups_response') }
  let(:mock_group_projects_response) { instance_double('group_projects_response') }

  let(:mock_groups) do
    [Gitlab::ObjectifiedHash.new({ id: '12345', name: 'Test Group' })]
  end

  let(:mock_group_projects) do
    [
      Gitlab::ObjectifiedHash.new({ id: '1', name: 'Test Project 1' }),
      Gitlab::ObjectifiedHash.new({ id: '2', name: 'Test Project 2' }),
      Gitlab::ObjectifiedHash.new({ id: '3', name: 'Test Project 3' })
    ]
  end

  def with_mock_gitlab_client
    allow(GGM).to receive(:gitlab_client).and_return(mock_gitlab_client)
  end

  def with_gitlab_groups_response_success
    allow(mock_gitlab_client).to receive(:groups).and_return(mock_groups_response)
    allow(mock_groups_response).to receive(:auto_paginate).and_return(mock_groups)
  end

  def with_gitlab_group_projects_response_success
    allow(mock_gitlab_client).to receive(:group_projects).and_return(mock_group_projects_response)
    allow(mock_group_projects_response).to receive(:auto_paginate).and_return(mock_group_projects)
  end

  def gitlab_404_response # rubocop:disable Metrics/AbcSize:
    allow(mock_gitlab_error_response).to receive(:parsed_response).and_return('Not Found')
    allow(mock_gitlab_error_response).to receive(:code).and_return('404')
    allow(mock_gitlab_request).to receive(:base_uri).and_return('https://gitlab.tests')
    allow(mock_gitlab_request).to receive(:path).and_return('/some/path')
    allow(mock_gitlab_error_response).to receive(:request).and_return(mock_gitlab_request)
    Gitlab::Error::NotFound.new(mock_gitlab_error_response)
  end
end

RSpec.configure do |config|
  config.include GitlabMocks

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
