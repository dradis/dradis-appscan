module Dradis::Plugins::Appscan
  class Importer < Dradis::Plugins::Upload::Importer
    # The framework will call this function if the user selects this plugin from
    # the dropdown list and uploads a file.
    # @returns true if the operation was successful, false otherwise
    def import(params = {})
      logger.info { "Parsing Appscan Source output from #{params[:file]}..." }
      doc = Nokogiri::XML(File.read(params[:file]))
      logger.info { 'Done.' }

      assessment_run = doc.xpath('/AssessmentRun').first

      logger.info { 'Validating Appscan Source output...' }
      unless assessment_run &&
             assessment_run.attribute('version') &&
             assessment_run.attribute('version').text =~ /^9\./
        error = {
          'Title' => 'Invalid file format',
          'File name' => File.basename(params[:file]),
          'Description' => "The file you uploaded doesn't seem to be a valid \
                            .ozasmt file."
        }
        logger.fatal { error['Description'] }
        error = error.map { |k, v| format("#[%s]#\n%s\n", k, v) }.join("\n\n")
        content_service.create_note text: error
        return false
      end
      logger.info { 'Done.' }

      logger.info { 'Processing report...' }
      @issues = {}
      @node   = content_service.create_node(label: 'Appscan Source')

      asmnt_files = assessment_run.xpath('Assessment/Assessment/AsmntFile')
      asmnt_files.each do |asmnt_file|
        findings = asmnt_file.xpath('Finding[not(@excluded)]')
        findings.to_a.uniq { |f| f[:data_id] }.each do |finding|
          evidence = Appscan::Evidence.new(finding, assessment_run)
          issue    = Appscan::Issue.new(evidence.vulnerability)

          process_vulnerability(issue)
          process_finding(evidence)
        end
      end

      logger.info { 'Report processed...' }
      true
    end

    private

    # Creates an evidence
    def process_finding(evidence)
      evidence_text =
        template_service.process_template(
          template: 'evidence',
          data: evidence
        )
      content_service.create_evidence(
        issue: @issues[evidence.description],
        node: @node,
        content: evidence_text
      )
    end

    # Creates an issue if the issue doesn't exist
    def process_vulnerability(issue)
      return unless @issues[issue.value].nil?

      issue_text = template_service.process_template(
        template: 'issue',
        data: issue
      )

      @issues[issue.value] =
        content_service.create_issue(text: issue_text, id: issue.value)

      logger.info { "Added vulnerability #{issue.value}" }
    end
  end
end
