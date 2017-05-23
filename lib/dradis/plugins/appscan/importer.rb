module Dradis::Plugins::Appscan
  class Importer < Dradis::Plugins::Upload::Importer
    # The framework will call this function if the user selects this plugin from
    # the dropdown list and uploads a file.
    # @returns true if the operation was successful, false otherwise
    def import(params = {})
      logger.info { "Parsing Appscan Source output from #{params[:file]}..." }
      doc = Nokogiri::XML(File.read(params[:file]))
      logger.info { 'Done.' }

      @assessment_run = doc.xpath('/AssessmentRun').first

      logger.info { 'Validating Appscan Source output...' }
      unless @assessment_run &&
             @assessment_run.attribute('version') &&
             @assessment_run.attribute('version').text =~ /^9\./
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

      asmnt_files = @assessment_run.xpath('Assessment/Assessment/AsmntFile')
      asmnt_files.each do |asmnt_file|
        findings = asmnt_file.xpath('Finding[not(@excluded)]')
        findings.to_a.uniq { |f| f[:data_id] }.each do |finding|
          finding_data  = finding_data_xpath(finding[:data_id])
          vulnerability = string_xpath(finding_data[:vtype])
          site          = site_xpath(finding_data[:site_id])
          file          = file_xpath(asmnt_file[:file_id])

          process_vulnerability(vulnerability)

          evidence_data =
            get_evidence_data(vulnerability, site, file)
          process_finding(evidence_data)
        end
      end

      logger.info { 'Report processed...' }
    end

    private

    # Extract all info that will be used to create an evidence
    def get_evidence_data(vulnerability, site, file)
      {
        description: vulnerability[:value],
        file: file[:value],
        line: site[:ln],
        column: site[:cn],
        method: string_xpath(site[:method])[:value],
        caller: string_xpath(site[:caller])[:value],
        context: string_xpath(site[:cxt])[:value]
      }
    end

    # Creates an evidence
    def process_finding(evidence_data)
      evidence_text =
        template_service.process_template(
          template: 'evidence',
          data: evidence_data
        )
      content_service.create_evidence(
        issue: @issues[evidence_data[:description]],
        node: @node,
        content: evidence_text
      )
    end

    # Returns issue with that description (vulnerability)
    # If the issue doesn't exist yet, create it
    def process_vulnerability(vulnerability)
      issue = @issues[vulnerability[:value]]
      return unless issue.nil?

      issue_text = template_service.process_template(
        template: 'issue',
        data: vulnerability
      )
      issue = content_service.create_issue(
        text: issue_text,
        id: vulnerability[:value]
      )
      @issues[vulnerability[:value]] = issue
      logger.info { "Added vulnerability #{vulnerability[:value]}" }
    end

    def file_xpath(file_id)
      @assessment_run.at_xpath("FilePool/File[@id='#{file_id}']")
    end

    def finding_data_xpath(finding_id)
      @assessment_run.at_xpath(
        "FindingDataPool/FindingData[@id='#{finding_id}']"
      )
    end

    def site_xpath(site_id)
      @assessment_run.at_xpath("SitePool/Site[@id='#{site_id}']")
    end

    def string_xpath(id)
      @assessment_run.at_xpath("StringPool/String[@id='#{id}']")
    end
  end
end
