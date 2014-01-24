module Gitlab
  class Auth
    def find(login, password)
      user = User.find_by_email(login) || User.find_by_username(login)

      if user.nil? || user.ldap_user?
        # Second chance - try LDAP authentication
        return nil unless ldap_conf.enabled

        Gitlab::LDAP::User.authenticate(login, password)
      elsif user && user.pam_user? && pam_conf.enabled
        Gitlab::PAM::User.authenticate(login, password)
      else
        user if user.valid_password?(password)
      end
    end

    def log
      Gitlab::AppLogger
    end

    def ldap_conf
      @ldap_conf ||= Gitlab.config.ldap
    end

    def pam_conf
      @pam_conf ||= Gitlab.config.pam
    end
  end
end
