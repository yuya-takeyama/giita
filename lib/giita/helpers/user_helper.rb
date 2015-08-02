require 'rack/utils'

module Giita
  module Helpers
    module UserHelper
      def link_to_user(user)
        user = user.login if user.respond_to? :login

        %Q{<a href="/users/%s">%s</a>} % [h(user), h(user)]
      end

      private
      def h(s)
        ::Rack::Utils.escape_html(s)
      end
    end
  end
end
