require 'giita/helpers/user_helper'
require 'giita/markdown_parser'

require 'sinatra/base'
require 'octokit'
require 'slim'
require 'omniauth-github'

module Giita
  class App < Sinatra::Base
    configure do
      if ENV['GITHUB_CLIENT_ID'] and ENV['GITHUB_CLIENT_SECRET']
        @@octokit = ::Octokit::Client.new(
          client_id: ENV['GITHUB_CLIENT_ID'],
          client_secret: ENV['GITHUB_CLIENT_SECRET'],
        )
      else
        raise 'Environmental variables GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET is not set'
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

      enable :sessions

      use ::OmniAuth::Builder do
        provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], {
          scope: ['repo']
        }
      end

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

      if ENV['HTTP_DUMP_ENABLE']
        require 'http-dump/enable'
        HTTPDump.output_encoding = 'utf-8'
      end
    end

    before do
      unless request.path_info =~ %r{/(?:auth/|login)}
        unless logged_in?
          redirect '/login?to=' + escape_uri(request.path_info)
        end
      end
    end

    get '/' do
      @issues = @@octokit.issues @@github_project, per_page: 20

      slim :index
    end

    get '/login' do
      slim :login
    end

    get '/auth/github/callback' do
      session['github_oauth'] = env['omniauth.auth'][:credentials]
      to = env['omniauth.params']['to']

      if to and to != ''
        redirect URI.parse(to).path
      else
        redirect '/'
      end
    end

    get '/auth/failure' do
      raise 'failure'
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

    helpers do
      def logged_in?
        session.key? 'github_oauth'
      end

      def escape_uri(s)
        ::Rack::Utils.escape s
      end

      def github_oauth_link
        if params[:to] and params[:to] != ''
          '/auth/github?to=' + escape_uri(params[:to])
        else
          '/auth/githuab'
        end
      end
    end
  end
end
