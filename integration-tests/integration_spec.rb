# frozen_string_literal: true

require 'gitlab'
require 'yaml'

# Disable some rspec best practices, as our integration tests need state to persist across each test
# rubocop:disable RSpec/BeforeAfterAll, RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/DescribeClass
describe 'Integration Tests' do
  before(:all) do
    Gitlab.private_token = ENV['GITLAB_TOKEN']
    @group = Gitlab.create_group('Integration Test Group', 'integration-test-group',
                                 { parent_id: ENV['INTEGRATION_TEST_PARENT_GROUP_ID'] })
    @projects = 5.times.map do |i|
      Gitlab.create_project("project#{i}", { namespace_id: @group.id })
    end
  end

  after(:all) do
    Gitlab.delete_group(@group.id)
  end

  context 'with basic config for a single file' do
    let(:basic_config) do
      { 'groups' => [
        { 'name' => @group.name,
          'include_subgroups' => false,
          'archived' => false,
          'files' => [
            { 'path' => 'hello.md' }
          ] }
      ] }.to_yaml
    end

    let(:file_contents) { "Hello World\n" }

    before do
      File.open('/tmp/hello.md', 'w') { |file| file.write(file_contents) }
      File.open('/tmp/.ggm.yaml', 'w') { |file| file.write(basic_config) }
    end

    it 'writes the expected file to every project' do
      @projects.each do |project|
        expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
      end

      Dir.chdir('/tmp') { `'ggm'` }

      @projects.each do |project|
        get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
        expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll, RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/DescribeClass
