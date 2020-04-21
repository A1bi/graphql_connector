# frozen_string_literal: true

module GraphqlConnector
  # Wrapper class for HTTParty post query
  class HttpClient
    def initialize(uri, headers)
      @uri = uri
      @headers = headers
    end

    def query(model, conditions, selected_fields)
      result_for('query', model, conditions, selected_fields)
    end

    def mutation(model, inputs, selected_fields)
      result_for('mutation', model, inputs, selected_fields)
    end

    def raw_query(query_string, variables: {})
      response = HTTParty.post(@uri,
                               headers: @headers,
                               body: { query: query_string,
                                       variables: variables })
      parsed_body = JSON.parse(response.body)
      verify_response!(parsed_body)
      parsed_body
    end

    private

    def result_for(type, model, inputs, selected_fields)
      query_string =
        QueryBuilder.new(type, model, inputs, selected_fields).create
      parsed_body = raw_query(query_string)
      result = parsed_body['data'][model.to_s]
      return OpenStruct.new(result) unless result.is_a? Array

      result.map { |entry| OpenStruct.new(entry) }
    end

    def verify_response!(parsed_body)
      return unless parsed_body.key? 'errors'

      raise CustomAttributeError, parsed_body['errors']
    end
  end
end
