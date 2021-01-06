# frozen_string_literal: true

require 'digest'

module GGM
  # A wrapper for files that could be remote/local
  # TODO: Support other types of file (http(s), github, gitlab etc.)
  class File
    attr_reader :content, :sha256sum, :uri, :options

    def initialize(uri, options: {})
      @uri = uri
      @content = ::File.read(@uri)
      @sha256sum = Digest::SHA256.hexdigest(@content)
      @options = options
    end

    def exists?(project, project_path: @uri, branch: 'master')
      GGM.gitlab_client.get_file(project.id, project_path, branch)
      true
    rescue Gitlab::Error::NotFound
      false
    end

    def exists_and_matches?(project, project_path: @uri, branch: 'master')
      file_metadata = GGM.gitlab_client.get_file(project.id, project_path, branch)
      file_metadata.content_sha256 == @sha256sum
    rescue Gitlab::Error::NotFound
      false
    end

    def location
      @uri
    end

    def to_s
      "GGM::File(#{@uri})"
    end
  end
end
