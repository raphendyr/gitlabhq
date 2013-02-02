module Gitlab
  class Auth
    def build_email(auth)
      provider = auth.provider.intern
      email = auth.info.email.to_s.downcase unless auth.info.email.nil?

      # we can workaround missing emails in omniauth provider backend
      # by setting email_domain option
      if email.nil? and not Devise.omniauth_configs[provider].options[:email_domain].nil?
        email = auth.info.nickname + "@" + Devise.omniauth_configs[provider].options[:email_domain]
      end

      email
    end

    def create_from_omniauth(auth, strong_oauth = false)
      provider = auth.provider
      uid = auth.info.uid || auth.uid
      uid = uid.to_s.force_encoding("utf-8")
      name = auth.info.name.to_s.force_encoding("utf-8")
      email = build_email(auth)

      raise OmniAuth::Error, "#{provider} does not provide an email address " \
          "nor there is no email_domain option" if email.nil?

      log.info "Creating user from #{provider} login"\
        " {uid => #{uid}, name => #{name}, email => #{email}}"
      password = Devise.friendly_token[0, 8].downcase
      @user = User.new({
        extern_uid: uid,
        provider: provider,
        name: name,
        username: email.match(/^[^@]*/)[0],
        email: email,
        password: password,
        password_confirmation: password,
        projects_limit: Gitlab.config.gitlab.default_projects_limit,
      }, as: :admin)
      if Gitlab.config.omniauth['block_auto_created_users'] && !strong_oauth
        @user.blocked = true
      end
      @user.save!
      @user
    end

    def find_or_new_for_omniauth(auth)
      provider, uid = auth.provider, auth.uid
      email = build_email(auth)
      strong_oauth = ['ldap', 'pam'].include?(provider)

      if strong_oauth
        raise OmniAuth::Error, "STRONG AUTH accounts (ldap, pam) must provide an uid and email address" if uid.nil? or email.nil?
      end

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy STRONG OAUTH user #{email} with extern_uid => #{uid}" if strong_oauth
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        if Gitlab.config.omniauth['allow_single_sign_on'] || strong_oauth
          @user = create_from_omniauth(auth, strong_oauth)
          @user
        end
      end
    end

    def log
      Gitlab::AppLogger
    end
  end
end
