# frozen_string_literal: true

describe GGM::Env do
  let(:truthy_values) { %w[t true yes y 1].freeze }
  let(:falsey_values) { %w[f false n no 0].freeze }

  it 'returns nil for nil environment variables' do
    expect(described_class['NOT_A_VAR']).to eq(nil)
  end

  %w[t true yes y 1].each do |val|
    it "returns true for variables set to #{val}" do
      ENV['TRUTHY_VAR'] = val.to_s
      expect(described_class['TRUTHY_VAR']).to eq(true)
    end
  end

  %w[f false n no 0].each do |val|
    it "returns false for variables set to #{val}" do
      ENV['FALSEY_VAR'] = val.to_s
      expect(described_class['FALSEY_VAR']).to eq(false)
    end
  end

  it 'returns a string for other values' do
    ENV['OTHER_VAR'] = 'My string'
    expect(described_class['OTHER_VAR']).to eq('My string')
  end
end
