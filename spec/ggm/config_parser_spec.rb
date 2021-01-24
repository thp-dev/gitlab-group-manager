# frozen_string_literal: true

describe GGM::ConfigParser do
  before do
    with_mock_gitlab_client
    with_gitlab_groups_response_success
    with_gitlab_group_projects_response_success
    with_gitlab_group_subgroups_response_success
  end

  describe '#new' do
    context 'with valid yaml' do
      subject(:config_parser) { described_class.new(config_file_path: 'spec/fixtures/config/.ggm.yaml') }

      let(:expected_config) do
        {
          'groups' =>
            [{ 'name' => 'Test Group',
               'archived' => false,
               'files' => [{ 'path' => 'spec/fixtures/test.md' },
                           { 'path' => 'spec/fixtures/another.md' }] }]
        }
      end

      it 'does not raise an error' do
        expect { config_parser.config }.not_to raise_error
      end

      it 'presents a hash' do
        expect(config_parser.config).to eq(expected_config)
      end

      it 'lists valid project sets' do
        expect(config_parser.project_set_configs.count).to eq(1)
      end
    end
  end

  context 'with invalid yaml' do
    subject(:bad_config_parser) { described_class.new(config_file_path: 'spec/fixtures/config/.bad.yaml') }

    it 'raises an error' do
      expect { bad_config_parser }.to raise_error GGM::ConfigError, 'Missing "groups" section'
    end
  end
end
