require 'datamapper'

module PivotalTracker
  class Resource
    include DataMapper::Resource

    def self.default_repository_name
      :pivotal
    end

    property :id,            Serial
    property :url,           String
    property :name,          String
    
    def to_xml
      "<pivotal_resource></pivotal_resource>"
    end
  end
end