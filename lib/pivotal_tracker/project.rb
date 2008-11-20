module PivotalTracker
  class Project
    include DataMapper::Resource

    def self.default_repository_name
      :pivotal
    end

    property :id,            Serial
    property :name,          String

    has n, :stories
  end
end