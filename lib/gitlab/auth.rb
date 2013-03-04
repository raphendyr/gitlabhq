module Gitlab
  class Auth
    def create_from_omniauth(uid, email, auth)
      provider = auth.provider
      name = auth.info.name.to_s.force_encoding("utf-8")

      raise SimpleError, "#{provider} does not provide an email address" if email.nil? or email.blank?

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
      trusted = Gitlab.config.trusted_omniauth.provider.to_s if Gitlab.config.trusted_omniauth.provider
      if Gitlab.config.omniauth['block_auto_created_users'] and provider != trusted
        @user.blocked = true
      end
      @user.save!
      @user
    end

    def find_or_new_for_omniauth(auth)
      provider = auth.provider
      provider_sym = provider.to_sym
      uid = auth.uid.to_s.force_encoding("utf-8")
      email = auth.info.email.to_s.downcase unless auth.info.email.nil?
      # we can workaround missing emails in omniauth provider
      # by setting email_domain option for that provider
      if email.nil?
        email_domain = Devise.omniauth_configs[provider_sym].options[:email_domain]
        email_user = auth.info.nickname
        email = "#{email_user}@#{email_domain}" unless email_user.nil? or email_domain.nil?
      end


      raise SimpleError, "Omniauth provider must provide uid" if uid.nil?

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy #{provider} user #{email} with extern_uid => #{uid}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        if Gitlab.config.omniauth['allow_single_sign_on'] or provider_sym == Gitlab.config.trusted_omniauth.provider
          @user = create_from_omniauth(uid, email, auth)
          @user
        end
      end
    end

    def log
      Gitlab::AppLogger
    end

    # TODO: reorder methods so private block may be used instead
    private :create_from_omniauth, :log
  end
end
