module Giita
  class MarkdownParser
    def initialize(octokit: , github_project: )
      @octokit = octokit
      @github_project = github_project
      @cache = Cache.new
    end

    def parse(markdown)
      parsed = @cache.get(markdown)

      unless parsed
        parsed = @octokit.markdown(markdown, {
          mode: 'gfm',
          context: @github_project,
        })
        parsed.force_encoding 'UTF-8'

        @cache.set(markdown, parsed)
      end

      parsed
    end

    # TODO: Replace with some gem
    class Cache
      def initialize
        require 'digest/sha2'
        @values = {}
      end

      def set(markdown, parsed)
        @values[to_key(markdown)] = parsed
      end

      def get(markdown)
        @values[to_key(markdown)]
      end

      private
      def to_key(markdown)
        ::Digest::SHA256.hexdigest markdown
      end
    end
  end
end
