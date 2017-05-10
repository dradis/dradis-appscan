module Dradis::Plugins::Appscan
  class Importer < Dradis::Plugins::Upload::Importer
    # The framework will call this function if the user selects this plugin from
    # the dropdown list and uploads a file.
    # @returns true if the operation was successful, false otherwise
    def import(params={})
      logger.info{ "Parsing Appscan Source output from #{ params[:file] }..." }
      doc = Nokogiri::XML( File.read(params[:file]) )
      logger.info{ 'Done.' }

      logger.info{ 'Validating Appscan Source output...' }
      @assessment_run = doc.xpath('/AssessmentRun').first
      unless @assessment_run &&
             @assessment_run.attribute("version") &&
             @assessment_run.attribute("version").text =~ /^9\./
        error = {
          'Title' => 'Invalid file format',
          'File name' => File.basename(params[:file]),
          'Description' => "The file you uploaded doesn't seem to be a valid .ozasmt file."
        }
        logger.fatal{ error['Description'] }
        error = error.map{|k,v| "#[%s]#\n%s\n" % [k, v] }.join("\n\n")
        content_service.create_note text: error
        return false
      end
      logger.info { 'Done.' }

      logger.info { 'Processing report...' }
      issues = {}
      node   = content_service.create_node(label: 'Appscan Source')

      asmnt_files = @assessment_run.xpath('Assessment/Assessment/AsmntFile')
      asmnt_files.each do |asmnt_file|
        findings = asmnt_file.xpath('Finding')
        already_processed = []
        findings.each do |finding|
          next if finding[:exclude] == "true"

          # we found a .ozasmt example with duplicated data_id's,
          # we make sure to process unique data_id's per file
          finding_id = finding[:data_id]
          next if already_processed.include?(finding_id)
          already_processed << finding_id

          evidence_data = process_evidence(asmnt_file[:file_id], finding_id)
          vulnerability = evidence_data[:description]

          # map vulnerability to issue, if the issue doesn't exist yet, create it
          issue = issues[vulnerability]
          if issue.nil?
            issue_text = template_service.process_template(template: 'issue', data: evidence_data)
            issue = content_service.create_issue(text: issue_text, id: vulnerability)
            issues[vulnerability] = issue
            logger.info { "Added vulnerability #{vulnerability}" }
          end

          # map finding to evidence
          evidence_text =
            template_service.process_template(template: 'evidence', data: evidence_data)
          content_service.create_evidence(
            issue: issues[vulnerability],
            node: node,
            content: evidence_text
          )
        end
      end

      logger.info {'Report processed...'}
    end

    private
    def process_evidence(file_id, finding_id)
      finding_data = @assessment_run.at_xpath("FindingDataPool/FindingData[@id='#{finding_id}']")
      site         = @assessment_run.at_xpath("SitePool/Site[@id='#{finding_data[:site_id]}']")
      file         = @assessment_run.at_xpath("FilePool/File[@id='#{file_id}']")

      {
        description: string_value(finding_data[:vtype]),
        file: file[:value],
        line: site[:ln],
        column: site[:cn],
        method: string_value(site[:method]),
        caller: string_value(site[:caller]),
        context: string_value(site[:cxt])
      }
    end

    def string_value(id)
      @assessment_run.at_xpath("StringPool/String[@id='#{id}']")[:value]
    end
  end
end
