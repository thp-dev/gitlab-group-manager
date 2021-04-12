# frozen_string_literal: true

module GGM
  module Configurable
    # Configurable to ensure merge request approval configuration is consistent across projects
    class MergeRequestApprovals
      DEFAULT_MERGE_APPROVAL_CONFIG = {
        'approvals_before_merge' => 1,
        'reset_approvals_on_push' => true,
        'disable_overriding_approvers_per_merge_request' => false,
        'merge_requests_author_approval' => false,
        'merge_requests_disable_committers_approval' => false,
        'require_password_to_approve' => false
      }.freeze

      def configure(project_set, config)
        project_set.projects.each do |project|
          ensure_merge_approval_config(project, config)
        end
      end

      def ensure_merge_approval_config(project, config)
        current_config = GGM.gitlab_client.project_merge_request_approvals(project.id).to_hash
        proposed_config = DEFAULT_MERGE_APPROVAL_CONFIG.merge(config)
        if current_config == proposed_config
          puts 'No change to MR Approval required'
        else
          GGM.dry_runnable("Update MR approval configuration to #{proposed_config}") do
            GGM.gitlab_client.edit_project_merge_request_approvals(project.id, proposed_config).to_hash
          end
        end
      end
    end
  end
end
