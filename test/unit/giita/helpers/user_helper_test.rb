require 'test_helper'
require 'giita/helpers/user_helper'

class Giita::Helpers::UserHelperTest < Test::Unit::TestCase
  include ::Giita::Helpers::UserHelper

  sub_test_case '#link_to_user' do
    test 'with string user name' do
      assert do
        link_to_user('yuya-takeyama') == %Q{<a href="/users/yuya-takeyama">yuya-takeyama</a>}
      end
    end

    test 'username is escaped' do
      assert do
        link_to_user('yuya-takeyama<br>') == %Q{<a href="/users/yuya-takeyama&lt;br&gt;">yuya-takeyama&lt;br&gt;</a>}
      end
    end

    test 'with user entity' do
      user = {}
      stub(user).login { 'yuya-takeyama' }

      assert do
        link_to_user(user) == %Q{<a href="/users/yuya-takeyama">yuya-takeyama</a>}
      end
    end
  end

  test '#link_to_user_with_avatar' do
    user = {}
    stub(user).login { 'yuya-takeyama' }
    stub(user).avatar_url { 'http://example.com/avatar.jpg' }

    assert_equal link_to_user_with_avatar(user), %Q{<a href="/users/yuya-takeyama"><img src="http:&#x2F;&#x2F;example.com&#x2F;avatar.jpg" alt="@yuya-takeyama" width="40" height="40"></a>}
  end
end
