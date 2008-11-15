require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe DataMapper::Adapters::PivotalAdapter do
  attr_reader :adapter
  
  before(:all) do
    DataMapper.setup(:pivotal, { :adapter => 'pivotal' })
    @adapter = DataMapper::Repository.adapters[:pivotal]
    
    class PivotalResource
      include DataMapper::Resource
      
      def self.default_repository_name
        :pivotal
      end
      
      property :id, String, :key => true
    end
  end

  it_should_behave_like 'a DataMapper Adapter'
end
