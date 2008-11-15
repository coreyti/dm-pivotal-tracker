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
      
      property :id,         Integer, :key => true
      property :parent_id,  Integer, :key => true
      property :url,        String
    end
  end

  it_should_behave_like 'a DataMapper Adapter'

  describe "Resource.all" do
    describe "when invoked for a non-nested Resource" do
      before(:all) do
        @resources = PivotalResource.all
      end

      it "gets a set of Resources" do
        mock_response('http://www.pivotaltracker.com/services/v1/pivotal_resources')

        @resources.should_not be_nil
        @resources.first.should be_an_instance_of(PivotalResource)
      end
    end

    describe "when invoked for a nested Resource" do
      before(:all) do
        @resources = PivotalResource.all(:parent_id => 100)
      end

      it "gets a set of Resources" do
        mock_response('http://www.pivotaltracker.com/services/v1/parents/100/pivotal_resources')

        @resources.should_not be_nil
        @resources.first.should be_an_instance_of(PivotalResource)
      end
    end

    def mock_response(target_url)
      response = Object.new
      mock(response).body { '<response><pivotal_resources><pivotal_resource><id>200</id><url>http://localhost/pivotal_resources/200</url></pivotal_resource><pivotal_resources></response>' }

      uri = Object.new
      mock(uri).host { 'www.pivotaltracker.com' }
      mock(uri).port { 80 }

      mock(URI).parse(target_url) { uri }
      mock(Net::HTTP).start('www.pivotaltracker.com', 80) { response }
    end
  end
end
