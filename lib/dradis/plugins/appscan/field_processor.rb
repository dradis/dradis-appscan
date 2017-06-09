module Dradis
  module Plugins
    module Appscan
      class FieldProcessor < Dradis::Plugins::Upload::FieldProcessor
        def post_initialize(_args = {})
          return unless @data.is_a? Nokogiri::XML::Element

          # Dealing with Plugin Manager.
          # Transform Nokogiri objects to Appscan service objects.
          if @data.name == 'AssessmentRun'
            finding = @data.xpath(\
              'Assessment/Assessment/AsmntFile/Finding[not(@excluded)]'\
            ).first
            @data = ::Appscan::Evidence.new(finding, @data)
          elsif @data.name == 'String'
            @data = ::Appscan::Issue.new(@data)
          end
        end

        def value(args = {})
          field = args[:field]
          _, name = field.split('.')

          @data.try(name) || 'n/a'
        end
      end
    end
  end
end
