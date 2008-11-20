require 'rubygems'
require 'hpricot'
require 'net/http'
require 'uri'

module DataMapper
  module Adapters
    class PivotalAdapter < AbstractAdapter
      include Extlib

      def create(resources)
        count = 0
        
        resources.each do |resource|
          ancestry_meta = ancestry_meta_TEMP(resource)
          resource_name = resource_name(resource.class)
          response      = http_post("#{ancestry_meta[:path]}/#{resource_name.pluralize}", resource.to_xml)
          success       = true # response.instance_of?(Net::HTTPCreated)
      
          if success
            count += 1
            result   = read_result(response, resource_name)
            resource.attributes = result[0]
          end
        end
        
        count
      end

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
          return nil if response_failed?(response)
          
          result   = read_result(response, resource_name, { :id => resource_id })
          values   = read_values(result[0], properties, repository)
          resource = model.load(values, query)
        end

        resource
      end

      def read_many(query)
        conditions = query.conditions

        if conditions.empty? # && query.limit == 1
          raise 'ERROR: not yet handling empty conditions (Resource.first ???)'
        else
          model         = query.model
          repository    = query.repository.name
          properties    = query.fields
          resource_name = resource_name(query.model)
          ancestry_meta = ancestry_meta(conditions)
          limiting_read = limiting_read(conditions)
          
          # TODO: consider refactoring to #read(query, set, many=false)

          response = http_get("#{ancestry_meta[:path]}/#{resource_name.pluralize}")
          return nil if response_failed?(response)

          result = read_result(response, resource_name, ancestry_meta[:data])
          Collection.new(query) do |collection|
            result.each do |entry|
              values = read_values(entry, properties, repository)
              collection.load(values)
            end
          end
        end
      end

      protected

      def http_get(resource_uri)
        http_request do |http, base|
          headers = { 'Token' => @uri[:token] }
          request = Net::HTTP::Get.new("#{base}#{resource_uri}", headers)
          http.request(request)
        end
      end

      def http_post(resource_uri, data)
        http_request do |http, base|
          headers = {
            'Content-Type' => 'application/xml',
            'Token'        => @uri[:token]
          }
          request = Net::HTTP::Post.new("#{base}#{resource_uri}", data, headers)
          http.request(request)
        end
      end

      def http_request
        response = nil
        base_uri = URI.parse(@uri[:server])

        Net::HTTP.start(base_uri.host, base_uri.port) do |http|
          response = yield(http, base_uri.path)
        end
        response
      end

      def resource_name(model)
        Inflection.underscore(model.name.split('::').last)
      end
      
      def ancestor_name(field_name)
        field_name.to_s.sub(/_id$/, '')
      end

      def ancestry_meta(conditions)
        meta = {
          :path => '',
          :data => {}
        }

        conditions.each do |condition|
          operator, field, value = condition
          if field.name.to_s =~ /.*_id$/
            meta[:path] << "/#{ancestor_name(field.name).pluralize}/#{value}"
            meta[:data][field.name] = value.is_a?(Array) ? value.first : value
          end
        end

        meta
      end

      def ancestry_meta_TEMP(resource)
        meta = {
          :path => '',
          :data => {}
        }

        resource.attributes.each do |attribute|
          attribute_name = attribute[0]
          if attribute_name.to_s =~ /.*_id$/
            value = resource.attribute_get(attribute_name)
            meta[:path] << "/#{ancestor_name(attribute_name).pluralize}/#{value}"
            meta[:data][attribute_name] = value.is_a?(Array) ? value.first : value
          end
        end

        meta
      end

      def limiting_read(conditions)
        conditions.each do |condition|
          operator, field, value = condition
          unless field.name.to_s =~ /.*id$/
            raise NotImplementedError.new
          end
        end
      end
      
      def response_failed?(response)
        response == Net::HTTPNotFound
      end

      def read_result(response, resource_name, defaults = {})
        results = []
        doc = Hpricot(response.body).at("response")
        
        (doc/"//#{resource_name}").each do |resource_node|
          result = defaults.dup
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

