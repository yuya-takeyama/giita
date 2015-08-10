require 'rack/utils'

module Giita
  class Pager
    attr_reader :has_next_page

    def initialize(page: , has_next_page: , request: )
      @page = page
      @has_next_page = has_next_page
      @request = request
    end

    def next_page_uri
      path = @request.path
      query_params = ::Rack::Utils.parse_query(@request.query_string)
      query_params['page'] = if query_params.key? 'page'
                               query_params['page'].to_i + 1
                             else
                               2
                             end
      query_string = ::Rack::Utils.build_query(query_params)
      path + (query_string and query_string != '' ? "?#{query_string}" : '')
    end

    def prev_page_uri
      path = @request.path
      query_params = ::Rack::Utils.parse_query(@request.query_string)
      query_params['page'] = if query_params.key? 'page'
                               query_params['page'].to_i - 1
                             else
                               1
                             end
      query_string = ::Rack::Utils.build_query(query_params)
      path + (query_string and query_string != '' ? "?#{query_string}" : '')
    end
  end
end
