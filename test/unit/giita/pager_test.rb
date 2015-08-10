require 'test_helper'
require 'giita/pager'

module Giita
  class PagerTest < Test::Unit::TestCase
    sub_test_case '#next_page_uri' do
      test 'without query params' do
        request = stub_request(path: '/issues', query_string: '')
        pager = Pager.new(page: 1, has_next_page: true, request: request)

        assert do
          pager.next_page_uri == '/issues?page=2'
        end
      end

      test 'with query params' do
        request = stub_request(path: '/issues', query_string: 'foo=bar')
        pager = Pager.new(page: 1, has_next_page: true, request: request)

        assert do
          pager.next_page_uri == '/issues?foo=bar&page=2'
        end
      end
    end

    sub_test_case '#prev_page_uri' do
      test 'without query params' do
        request = stub_request(path: '/issues', query_string: '')
        pager = Pager.new(page: 2, has_next_page: true, request: request)

        assert do
          pager.prev_page_uri == '/issues?page=1'
        end
      end

      test 'with query params' do
        request = stub_request(path: '/issues', query_string: 'foo=bar')
        pager = Pager.new(page: 2, has_next_page: true, request: request)

        assert do
          pager.prev_page_uri == '/issues?foo=bar&page=1'
        end
      end
    end

    def stub_request(path: , query_string: )
      request = {path: path, query_string: query_string}
      stub(request).path { path }
      stub(request).query_string { query_string }
      request
    end
  end
end
