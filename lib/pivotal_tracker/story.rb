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

    # TODO: CTI - blech! get rid of this.
    def to_xml(options = {})
      xml = "<story>"
      if options[:only] == :dirty
        dirty_attributes.each do |attribute, value|
          xml << "<#{attribute.name}>#{value}</#{attribute.name}>"
        end
      else
        loaded_attributes.each do |attr_name|
          attr_value = attribute_get(attr_name)
          xml << "<#{attr_name}>#{attr_value}</#{attr_name}>" unless attr_value.blank? || attr_name.to_s =~ /.*_id$/
        end
      end
      xml + "</story>"
    end
  end
end