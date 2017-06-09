module Appscan
  # This class represents an Evidence in the Appscan .ozasmt xml file
  # XML document.
  #
  # It provides a convenient way to access the information scattered all over
  # the XML in attributes and nested tags.
  class Evidence
    # Accepts two XML nodes from Nokogiri::XML.
    def initialize(finding, assessment_run)
      @assessment_run    = assessment_run
      @finding_data_xml  = finding_data_xpath(finding[:data_id])
      @site_xml          = site_xpath(@finding_data_xml[:site_id])
    end

    def caller
      @caller ||= string_xpath(@site_xml[:caller])[:value]
    end

    def column
      @site_xml[:cn]
    end

    def context
      @context ||= string_xpath(@site_xml[:cxt])[:value]
    end

    def description
      vulnerability[:value]
    end

    def file
      @file ||= file_xpath(@site_xml[:file_id])[:value]
    end

    def line
      @site_xml[:ln]
    end

    def method
      @method ||= string_xpath(@site_xml[:method])[:value]
    end

    def vulnerability
      @vulnerability ||= string_xpath(@finding_data_xml[:vtype])
    end

    private

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
