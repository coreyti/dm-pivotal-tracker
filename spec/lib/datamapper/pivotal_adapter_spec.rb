require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe DataMapper::Adapters::PivotalAdapter do
  attr_reader :adapter
  
  before(:all) do
    DataMapper.setup(:pivotal, { :adapter => 'pivotal' })
    @adapter = DataMapper::Repository.adapters[:pivotal]
    
    class ParentResource
      include DataMapper::Resource
      
      def self.default_repository_name
        :pivotal
      end
      
      property :id,   Serial
      property :url,  String

      has n, :pivotal_resources
    end

    class PivotalResource
      include DataMapper::Resource
      
      def self.default_repository_name
        :pivotal
      end
      
      property :id,   Serial
      property :url,  String
      
      belongs_to :parent_resource
    end
  end

  it_should_behave_like 'a DataMapper Adapter'

  describe "Resource.all" do
    attr_reader :resources
    
    # describe "when invoked for a non-nested Resource" do
    #   before(:all) do
    #     @resources = PivotalResource.all
    #   end
    # 
    #   it "gets a set of Resources" do
    #     mock_request('http://www.pivotaltracker.com/services/v1/pivotal_resources')
    # 
    #     @resources.should_not be_nil
    #     @resources.first.should be_an_instance_of(PivotalResource)
    #   end
    # end
    
    describe "when invoked through a Resource association" do
      attr_reader :resources

      before(:all) do
        parent = ParentResource.all(:id => 100).first
        @resources = parent.pivotal_resources
      end
      
      it "gets a set of resources" do
        mock_request('http://www.pivotaltracker.com/services/v1/parent_resources/100/pivotal_resources')

        resources.should_not be_nil
        resource = resources.first
        resource.should be_an_instance_of(PivotalResource)
        resource.id.should == 200
        resource.url.should == 'http://localhost/parent_resources/100/pivotal_resources/200'
        resource.parent_resource_id.should == 100
      end
    end
    
    def mock_request(target_url)
      response = Object.new
      mock(response).body {
        '<response><pivotal_resources><pivotal_resource><id>200</id><url>http://localhost/parent_resources/100/pivotal_resources/200</url><parent_resource_id>100</parent_resource_id></pivotal_resource><pivotal_resources></response>'
      }

      uri = Object.new
      mock(uri).host { 'www.pivotaltracker.com' }
      mock(uri).port { 80 }

      mock(URI).parse(target_url) { uri }
      mock(Net::HTTP).start('www.pivotaltracker.com', 80) { response }
    end
  end
end
