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

    def current?(today = Date.today)
      !iteration.nil? && iteration.start <= today && iteration.finish >= today
    end

    # TODO: CTI - blech! get rid of this.
    def to_xml
      xml = "<story>"
      loaded_attributes.each do |attr_name|
        attr_value = attribute_get(attr_name)
        xml << "<#{attr_name}>#{attr_value}</#{attr_name}>" unless attr_value.blank?
      end
      xml + "</story>"
    end
  end
end