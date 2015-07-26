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

      app_root = File.dirname(__FILE__) + '/../..'
      set :public_folder, app_root + '/public'
      set :views, app_root + '/views'
    end

    configure :development do
      require 'sinatra/reloader' if development?
      register Sinatra::Reloader
    end

    get '/' do
      @issues = @@octokit.issues @@github_project, per_page: 20

      slim :index
    end

    get '/items/:number' do
      @issue = @@octokit.issue @@github_project, params[:number]
      @parsed_body = @@octokit.markdown(@issue.body, {mode: 'gfm', context: @@github_project})
      @parsed_body.force_encoding "UTF-8"

      slim :'items/index', locals: {
        title: @issue.title
      }
    end

    get '/style.css' do
      sass :style
    end
  end
end
