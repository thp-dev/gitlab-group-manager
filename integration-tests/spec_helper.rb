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

# deletes a gitlab group, and wait for it to be properly removed
def delete_group_and_wait(group_id)
  group_still_exists = true
  Gitlab.delete_group(group_id)
  while group_still_exists
    begin
      Gitlab.group(group_id)
      sleep 1
    rescue StandardError
      group_still_exists = false
    end
  end
end
