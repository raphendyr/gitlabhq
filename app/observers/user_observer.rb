class UserObserver < ActiveRecord::Observer
  def after_create(user)
    log_info("User \"#{user.name}\" (#{user.email}) was created")

    # email user his username and password, if he logged with untrusted auth
    if Gitlab.config.trusted_omniauth.provider.to_s != user.provider
      Notify.delay.new_user_email(user.id, user.password)
    end
  end

  def after_destroy user
    log_info("User \"#{user.name}\" (#{user.email})  was removed")
  end

  def after_save user
    if user.username_changed?
      if user.namespace
        user.namespace.update_attributes(path: user.username)
      else
        user.create_namespace!(path: user.username, name: user.username)
      end
    end
  end

  protected

  def log_info message
    Gitlab::AppLogger.info message
  end
end
