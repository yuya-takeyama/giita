require 'giita/helpers/user_helper'
require 'giita/issue_finder'
require 'giita/markdown_parser'

require 'sinatra/base'
require 'octokit'
require 'slim'
require 'omniauth-github'

module Giita
  class App < Sinatra::Base
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

      @@markdown_parser = MarkdownParser.new(
        octokit: @@octokit,
        github_project: @@github_project,
      )
      @@issue_finder = IssueFinder.new(
        octokit: @@octokit,
        github_project: @@github_project,
      )

      enable :sessions
      set :session_secret, ENV['SESSION_SECRET']

      use ::OmniAuth::Builder do
        provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], {
          scope: ['repo']
        }
      end

      app_root = File.dirname(__FILE__) + '/../..'
      set :root, app_root
      set :public_folder, root + '/public'
      set :views, root + '/views'

      helpers Helpers::UserHelper
    end

    before do
      unless request.path_info =~ %r{/(?:auth/|login)}
        unless logged_in?
          redirect login_uri
        end
      end

      if logged_in?
        @@octokit.access_token = session['github_oauth']['token']
      end
    end

    get '/' do
      @issues, @pager = @@issue_finder.issues(request)

      slim :index
    end

    get '/login' do
      if logged_in?
        redirect '/'
      else
        slim :login
      end
    end

    get '/logout' do
      session.clear

      redirect login_uri_for(only_path(params[:to]))
    end

    get '/auth/github/callback' do
      session['github_oauth'] = env['omniauth.auth'][:credentials]
      to = env['omniauth.params']['to']

      if to and to != ''
        redirect only_path(to)
      else
        redirect '/'
      end
    end

    get '/auth/failure' do
      raise 'failure'
    end

    get '/users/:user_login' do
      @issues, @pager = @@issue_finder.user_issues(params[:user_login], request)
      @user = @@octokit.user params[:user_login]

      slim :'users/show'
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
      def h(text)
        ::Rack::Utils.escape_html text
      end

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
          '/auth/github'
        end
      end

      def github_user
        @github_user ||= @@octokit.user
      end

      def login_uri
        login_uri_for request.path_info
      end

      def login_uri_for(path)
        '/login?to=' + escape_uri(path)
      end

      def logout_uri
        '/logout?to=' + escape_uri(request.path_info)
      end

      def mypage_uri
        "/users/" + github_user.login if logged_in?
      end

      def only_path(uri)
        URI.parse(uri).path
      end

      def link_to_issue(issue)
        uri = '/users/%s/items/%d' % [escape_uri(issue.user.login), issue.number]
        '<a href="%s">%s</a>' % [h(uri), h(issue.title)]
      end
    end
  end
end
