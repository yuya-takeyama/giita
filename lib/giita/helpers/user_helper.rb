require 'rack/utils'

module Giita
  module Helpers
    module UserHelper
      def link_to_user(user)
        user = user.login if user.respond_to? :login

        %Q{<a href="/users/%s">@%s</a>} % [h(user), h(user)]
      end

      def link_to_user_with_avatar(user)
        %Q{<a href="/users/%s"><img src="%s" alt="@%s" width="40" height="40"></a>} % [
          h(user.login),
          h(user.avatar_url),
          h(user.login),
        ]
      end

      private
      def h(s)
        ::Rack::Utils.escape_html(s)
      end
    end
  end
end
