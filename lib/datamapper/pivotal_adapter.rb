module DataMapper
  module Adapters
    class PivotalAdapter < AbstractAdapter

      def create(resources)
        resources.each do |resource|
          path = File.join(File.dirname(__FILE__), '..', '..', 'fake', resource.path)
          File.open(path, 'w') { |f| f.write(resource.text) }
        end
      end
      
    end
  end
end
