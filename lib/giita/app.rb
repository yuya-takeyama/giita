require 'giita/helpers/user_helper'
require 'giita/markdown_parser'

require 'sinatra/base'
require 'octokit'
require 'slim'

module Giita
  class App < Sinatra::Base
    configure do
      if ENV['GITHUB_ACCESS_TOKEN']
        @@octokit = ::Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      else
        raise 'Environmental variable GITHUB_ACCESS_TOKEN is not set'
      end

      if ENV['GITHUB_PROJECT']
        @@github_project = ENV['GITHUB_PROJECT']
      else
        raise 'Environmental variable GITHUB_PROJECT is not set'
      end

      @@markdown_parser = ::Giita::MarkdownParser.new(
        octokit: @@octokit,
        github_project: @@github_project,
      )

      app_root = File.dirname(__FILE__) + '/../..'
      set :root, app_root
      set :public_folder, root + '/public'
      set :views, root + '/views'

      helpers ::Giita::Helpers::UserHelper
    end

    configure :development do
      require 'sinatra/reloader' if development?
      register Sinatra::Reloader
      require 'better_errors'
      use ::BetterErrors::Middleware
      ::BetterErrors.application_root = settings.root
    end

    get '/' do
      @issues = @@octokit.issues @@github_project, per_page: 20

      slim :index
    end

    get '/users/:user_login/items/:number' do
      @issue = @@octokit.issue @@github_project, params[:number]
      @issue.parsed_body = @@markdown_parser.parse(@issue.body)
      @comments = @@octokit
        .issue_comments(@@github_project, params[:number])
        .map do |comment|
          comment.parsed_body = @@markdown_parser.parse(comment.body)
          comment
        end

      slim :'items/show', locals: {
        title: @issue.title
      }
    end

    get '/style.css' do
      sass :style
    end
  end
end
