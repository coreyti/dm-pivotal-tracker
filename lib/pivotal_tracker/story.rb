module PivotalTracker
  class Story
    include DataMapper::Resource

    def self.default_repository_name
      :pivotal
    end

    property :id,            Serial
    property :url,           String
    property :name,          String
    property :description,   String
    property :story_type,    String
    property :estimate,      Integer
    property :requested_by,  String
    property :current_state, String
    property :created_at,    String
    
    belongs_to :project
    has 1, :iteration
  end
end