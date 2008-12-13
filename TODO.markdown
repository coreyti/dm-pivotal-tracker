dm-pivotal-tracker
==================

TODO
------------------

  * Use DataMapper::Resource scopes to provide filtering
  * Explore DataMapper many-to-many associations with anonymous resources
    (i.e., `:through => Resource`)
    
        class Story
          include DataMapper::Resource
          
          has n, :labels, :through => Resource
        end
        
        class Label
          include DataMapper::Resource
          
          has n, :stories, :through => Resource
        end
  * next...