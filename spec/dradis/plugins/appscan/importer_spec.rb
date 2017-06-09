require 'spec_helper'

describe Dradis::Plugins::Appscan::Importer do
  before(:each) do
    # Stub template service
    templates_dir = File.expand_path('../../../../../templates', __FILE__)
    expect_any_instance_of(Dradis::Plugins::TemplateService)
    .to receive(:default_templates_dir).and_return(templates_dir)

    plugin = Dradis::Plugins::Appscan

    @content_service = Dradis::Plugins::ContentService::Base.new(
      logger: Logger.new(STDOUT),
      plugin: plugin
    )

    @importer = described_class.new(
      content_service: @content_service
    )
  end

  it "creates the appropriate Dradis items" do
    allow(@content_service).to receive(:create_issue) do |args|
      OpenStruct.new(args)
    end
    allow(@content_service).to receive(:create_evidence) do |args|
      OpenStruct.new(args)
    end
    expect(@content_service).to receive(:create_node).with(hash_including label: 'Appscan Source').once
    expect(@content_service).to receive(:create_issue).exactly(7).times
    expect(@content_service).to receive(:create_evidence).exactly(9).times

    @importer.import(file: 'spec/fixtures/files/appscansource_sample.ozasmt')
  end
end
