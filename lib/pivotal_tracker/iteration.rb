module PivotalTracker
  class Iteration
    include DataMapper::Resource

    def self.default_repository_name
      :pivotal
    end

    property :id,     Serial
    property :number, Integer
    property :start,  Date
    property :finish, Date
  end
end