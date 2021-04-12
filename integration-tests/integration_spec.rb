# frozen_string_literal: true

require_relative 'spec_helper'

require 'gitlab'
require 'yaml'

# Disable some rspec best practices, as our integration tests need state to persist across each test
# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/DescribeClass
describe 'Integration Tests' do
  before do
    Gitlab.private_token = ENV['GITLAB_TOKEN']
    @group = Gitlab.group(ENV['INTEGRATION_TEST_GROUP_ID'])
    @projects = 3.times.map do |i|
      Gitlab.create_project("project#{i}", { namespace_id: @group.id })
    end
    @all_projects = @projects
    subgroups = ENV['INTEGRATION_TEST_SUB_GROUPS'].split(',')
    @sub_groups_and_projects = subgroups.each_with_index.map do |subgroup_id, i|
      group = Gitlab.group(subgroup_id)
      projects = 2.times.map do |j|
        Gitlab.create_project("sub-group-#{i}-project#{j}", { namespace_id: group.id })
      end
      @all_projects += projects
      { group: group, projects: projects }
    end
  end

  after do
    delete_projects(@all_projects)
  end

  context 'with basic config for a single file' do
    let(:basic_config) do
      { 'groups' => [
        { 'name' => @group.name,
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

    it 'writes the expected file to expected projects' do
      @projects.each do |project|
        expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
      end

      run_ggm

      # projects in main groups are included
      @projects.each do |project|
        get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
        expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
      end

      # projects in sub groups are included too
      @sub_groups_and_projects.each do |tuple|
        tuple[:projects].each do |project|
          get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
          expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
        end
      end
    end
  end

  context 'with certain subgroups excluded' do
    let(:basic_config) do
      { 'groups' => [
        { 'name' => @group.name,
          'excluded_subgroups' => ['Integration Test SubGroup 2'],
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

    it 'writes the expected file to expected projects' do
      @projects.each do |project|
        expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
      end

      run_ggm

      # projects in main groups are included
      @projects.each do |project|
        get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
        expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
      end

      # projects in subgroups 0 & 1 are also included
      @sub_groups_and_projects.first(2).each do |tuple|
        tuple[:projects].each do |project|
          get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
          expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
        end
      end

      # projects in subgroup 2 are not included
      @sub_groups_and_projects.last[:projects].each do |project|
        expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
      end
    end
  end

  context 'with all subgroups excluded' do
    let(:basic_config) do
      { 'groups' => [
        { 'name' => @group.name,
          'excluded_subgroups' => ['.*'],
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

    it 'writes the expected file to expected projects' do
      @projects.each do |project|
        expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
      end

      run_ggm

      # projects in main groups are included
      @projects.each do |project|
        get_file_response = Gitlab.get_file(project.id, 'hello.md', 'master')
        expect(get_file_response.content_sha256).to eq(Digest::SHA256.hexdigest(file_contents))
      end

      # projects in subgroups are excluded
      @sub_groups_and_projects.each do |tuple|
        tuple[:projects].each do |project|
          expect { Gitlab.get_file(project.id, 'hello.md', 'master') }.to raise_error(Gitlab::Error::NotFound)
        end
      end
    end
  end

  context 'with commit message prefixes and suffixes' do
    let(:basic_config) do
      { 'groups' => [
        { 'name' => @group.name,
          'archived' => false,
          'files' => [
            { 'path' => 'one.md', 'commit_suffix' => ' [skip ci]' },
            { 'path' => 'two.md', 'commit_prefix' => 'Auto-generated by GGM: ' }
          ] }
      ] }.to_yaml
    end

    let(:file_contents) { "Hello World\n" }

    before do
      File.open('/tmp/one.md', 'w') { |file| file.write(file_contents) }
      File.open('/tmp/two.md', 'w') { |file| file.write(file_contents) }
      File.open('/tmp/.ggm.yaml', 'w') { |file| file.write(basic_config) }
    end

    it 'writes the expected files to the expected project with the expected commit message' do
      run_ggm

      @projects.each do |project|
        commits = Gitlab.commits(project.id, { ref: 'master' }).auto_paginate
        suffix_commit, prefix_commit = commits.sort_by(&:created_at).last(2)
        expect(suffix_commit.message).to eq('Created file: one.md [skip ci]')
        expect(prefix_commit.message).to eq('Auto-generated by GGM: Created file: two.md')
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations, RSpec/InstanceVariable, RSpec/DescribeClass
