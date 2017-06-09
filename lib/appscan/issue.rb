module Appscan
  # This class represents an Evidence in the Appscan .ozasmt xml file
  # XML document.
  #
  # It is a simple map from a <String> Nokogiri element to a service object.
  # Done like this for consistency with the Evidence class, where the service
  # object is more necessary, since evidence info is scattered all over the XML.
  class Issue
    # Accepts a XML node from Nokogiri::XML.
    def initialize(vulnerability_xml)
      @vulnerability_xml = vulnerability_xml
    end

    def value
      @vulnerability_xml[:value]
    end
  end
end
