module Gitlab
  class Auth
    def find_for_ldap_auth(auth, signed_in_resource = nil)
      uid = auth.info.uid
      provider = auth.provider
      email = auth.info.email.downcase unless auth.info.email.nil?
      raise OmniAuth::Error, "LDAP accounts must provide an uid and email address" if uid.nil? or email.nil?

      if @user = User.find_by_extern_uid_and_provider(uid, provider)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy LDAP user #{email} with extern_uid => #{uid}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        create_from_omniauth(uid, email, auth)
      end
    end

    def create_from_omniauth(uid, email, auth)
      provider = auth.provider
      name = auth.info.name.to_s.force_encoding("utf-8")

      raise Omniauth::Error, "#{provider} does not provide an email address" if email.nil? or email.blank?

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
      @user.save!

      trusted = Gitlab.config.trusted_omniauth.provider.to_s if Gitlab.config.trusted_omniauth.provider
      if Gitlab.config.omniauth['block_auto_created_users'] and provider != trusted
        @user.block
      end

      @user
    end

    def find_or_new_for_omniauth(auth)
      provider = auth.provider
      uid = auth.uid.to_s.force_encoding("utf-8")
      email = auth.info.email.downcase unless auth.info.email.nil?

      raise Omniauth::Error, "Omniauth provider must provide uid" if uid.nil?

      if @user = User.find_by_provider_and_extern_uid(provider, uid)
        @user
      elsif @user = User.find_by_email(email)
        log.info "Updating legacy #{provider} user #{email} with extern_uid => #{uid}"
        @user.update_attributes(:extern_uid => uid, :provider => provider)
        @user
      else
        trusted = Gitlab.config.trusted_omniauth.provider.to_s if Gitlab.config.trusted_omniauth.provider
        if Gitlab.config.omniauth['allow_single_sign_on'] or provider == trusted
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
