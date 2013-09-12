module Gitlab
  class Auth
    def find(login, password)
      user = User.find_by(email: login) || User.find_by(username: login)

      if user.nil? || user.ldap_user?
        # Second chance - try LDAP authentication
        Gitlab::LDAP::User.authenticate(login, password)
      elsif user.nil? || user.pam_user?
        # If no user in db or the user is pam user, then auth using pam
        Gitlab::PAM::User.authenticate(login, password)
      else
        user if user.valid_password?(password)
      end
    end
  end
end
