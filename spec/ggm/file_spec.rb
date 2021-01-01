# frozen_string_literal: true

describe GGM::File do
  subject(:file) { described_class.new('spec/fixtures/hello.md') }

  let(:expected_hello_md_sha256sum) { 'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e' }

  before do
    with_mock_gitlab_client
  end

  describe '#new' do
    context 'with a file that exists locally' do
      it 'stores file contents in memory' do
        expect(file.content).to eq('Hello World')
      end

      it 'stores a sha256 checksum of the file' do
        expect(file.sha256sum).to eq(expected_hello_md_sha256sum)
      end

      it 'sets uri to the provided path' do
        expect(file.uri).to eq('spec/fixtures/hello.md')
      end
    end
  end

  describe '#location' do
    it 'returns the provided file path' do
      expect(file.location).to eq('spec/fixtures/hello.md')
    end
  end

  describe '#to_s' do
    it 'includes the file path' do
      expect(file.to_s).to match(%r{.*spec/fixtures/hello.md.*})
    end
  end

  describe '#exists?' do
    let(:project) { instance_double('gitlab_project') }

    before do
      allow(project).to receive(:id).and_return('12345')
    end

    context 'with a file that exists locally and a project that does contains a file of that name' do
      before do
        allow(mock_gitlab_client).to receive(:get_file)
      end

      it 'returns true' do
        expect(file.exists?(project)).to eq(true)
      end
    end

    context 'with a file that exists locally and a project that does not contain a file of that name' do
      before do
        allow(mock_gitlab_client).to receive(:get_file).and_raise(gitlab_404_response)
      end

      it 'returns false' do
        expect(file.exists?(project)).to eq(false)
      end
    end
  end

  describe '#exists_and_matches?' do
    let(:project) { instance_double('gitlab_project') }
    let(:mock_file_metadata) { instance_double('file_metadata') }

    before do
      allow(project).to receive(:id).and_return('12345')
    end

    context 'with a file that exists locally and a project that does contains the matching file' do
      before do
        allow(mock_file_metadata).to receive(:content_sha256).and_return(expected_hello_md_sha256sum)
        allow(mock_gitlab_client).to receive(:get_file).and_return(mock_file_metadata)
      end

      it 'returns true' do
        expect(file.exists_and_matches?(project)).to eq(true)
      end
    end

    context 'with a file that exists locally and a project that contains a different file of that name' do
      before do
        allow(mock_gitlab_client).to receive(:get_file).and_raise(gitlab_404_response)
        allow(mock_file_metadata).to receive(:content_sha256).and_return('some other sha256 hash')
      end

      it 'returns false' do
        expect(file.exists_and_matches?(project)).to eq(false)
      end
    end
  end
end
