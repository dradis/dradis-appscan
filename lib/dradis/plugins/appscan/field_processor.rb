module Dradis
  module Plugins
    module Appscan

      class FieldProcessor < Dradis::Plugins::Upload::FieldProcessor
        # def post_initialize(args={})
        # end

        def value(args={})
          field = args[:field]
          _, name = field.split('.')

          @data[name.to_sym] || 'n/a'
        end
      end
    end
  end
end
