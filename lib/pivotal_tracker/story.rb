require 'datamapper'

module PivotalTracker
  class Story
    include DataMapper::Resource

    def self.default_repository_name
      :pivotal
    end

    property :id,           Serial
    property :url,          String
    property :name,         String
    property :description,  String
    property :estimate,     Integer
    
    belongs_to :project
    has 1, :interation

    def initialize(id, name, description, estimate, iteration)
      @id           = id
      @name         = name
      @description  = description
      @estimate     = estimate
      @iteration    = iteration
    end

    def current?(today = Date.today)
      !@iteration.nil? && @iteration.starts_on <= today && @iteration.ends_on >= today
    end
  end
end