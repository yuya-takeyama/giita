require 'giita/pager'

module Giita
  class IssueFinder
    def initialize(octokit: , github_project: )
      @octokit = octokit
      @github_project = github_project
      @per_page = 20
    end

    def issues(request)
      page = request.params['page'].to_i
      page = 1 if page < 1

      issues = @octokit.issues(@github_project, page: page, per_page: @per_page)

      has_next_page = !!@octokit.last_response.rels[:next]

      [
        issues,
        Pager.new(
          page: page,
          has_next_page: has_next_page,
          request: request,
        )
      ]
    end

    def user_issues(author, request)
      page = request.params['page'].to_i
      page = 1 if page < 1

      q = "author:#{author} type:issue repo:#{@github_project}"
      result = @octokit.search_issues(q, page: page, per_page: @per_page)

      has_next_page = !!@octokit.last_response.rels[:next]

      [
        result.items,
        Pager.new(
          page: page,
          has_next_page: has_next_page,
          request: request,
        )
      ]
    end
  end
end
