module Dradis
  module Plugins
    module Appscan
      class Engine < ::Rails::Engine
        isolate_namespace Dradis::Plugins::Appscan

        include ::Dradis::Plugins::Base
        description 'Processes Appscan Source XML format'
        provides :upload
      end
    end
  end
end
