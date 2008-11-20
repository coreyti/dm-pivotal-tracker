require 'rubygems'
require 'hpricot'
require 'net/http'
require 'uri'

module DataMapper
  module Adapters
    class PivotalAdapter < AbstractAdapter
      include Extlib

      def read_one(query)
        resource   = nil
        conditions = query.conditions

        if conditions.empty? # && query.limit == 1
          raise 'ERROR: not yet handling empty conditions (Resource.first ???)'
        else
          model         = query.model
          repository    = query.repository.name
          properties    = query.fields
          resource_name = resource_name(query.model)
          resource_id   = conditions.first[2]

          # TODO: consider refactoring to #read(query, set, many=false)

          response = http_get("/#{resource_name.pluralize}/#{resource_id}")
          result   = read_result(response, resource_name, { :id => resource_id })
          values   = read_values(result[0], properties, repository)

          resource = model.load(values, query)
        end

        resource
      end
      
      protected

      def http_get(resource_uri)
        request do |http|
          puts 'ALERT! real request {}'
          request = Net::HTTP::Get.new(resource_uri)
          http.request(request)
        end
      end
      
      def request
        response = nil
        base_uri = URI.parse(@uri[:server])

        Net::HTTP.start(base_uri.host, base_uri.port) do |http|
          puts 'ALERT! real Net::HTTP.start'
          response = yield(http)
        end
        response
      end
      
      def resource_name(model)
        Inflection.underscore(model.name.split('::').last)
      end
      
      def read_result(response, resource_name, defaults = {})
        results = []
        doc = Hpricot(response.body).at("response")
        
        (doc/"/#{resource_name}").each do |resource_node|
          result = defaults
          resource_node.children.each do |child|
            if child.is_a?(Hpricot::Elem)
              as_int = child.inner_html.to_i
              result[child.name.intern] = (as_int == 0 ? child.inner_html : as_int)
            end
          end
          
          results << result
        end
        
        results
      end
      
      def read_values(result, properties, repository)
        properties.map { |property| result[property.field(repository).intern] }
      end
    end
  end
end

