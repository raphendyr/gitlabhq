require 'digest/md5'
require 'uri'

module ApplicationHelper

  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  def current_controller?(*args)
    args.any? { |v| v.to_s.downcase == controller.controller_name }
  end

  # Check if a partcular action is the current one
  #
  # args - One or more action names to check
  #
  # Examples
  #
  #   # On Projects#new
  #   current_action?(:new)           # => true
  #   current_action?(:create)        # => false
  #   current_action?(:new, :create)  # => true
  def current_action?(*args)
    args.any? { |v| v.to_s.downcase == action_name }
  end

  def gravatar_icon(user_email = '', size = nil)
    size = 40 if size.nil? || size <= 0

    if !Gitlab.config.gravatar.enabled || user_email.blank?
      'no_avatar.png'
    else
      gravatar_url = request.ssl? ? Gitlab.config.gravatar.ssl_url : Gitlab.config.gravatar.plain_url
      user_email.strip!
      sprintf gravatar_url, hash: Digest::MD5.hexdigest(user_email.downcase), size: size
    end
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_in_words(project.repository.commit.committed_date) + " ago"
    else
      "Never"
    end
  rescue
    "Never"
  end

  def grouped_options_refs(destination = :tree)
    repository = @project.repository

    options = [
      ["Branch", repository.branch_names ],
      [ "Tag", repository.tag_names ]
    ]

    # If reference is commit id -
    # we should add it to branch/tag selectbox
    if(@ref && !options.flatten.include?(@ref) &&
       @ref =~ /^[0-9a-zA-Z]{6,52}$/)
      options << ["Commit", [@ref]]
    end

    grouped_options_for_select(options, @ref || @project.default_branch)
  end

  def search_autocomplete_source
    unless current_user.nil?
      projects = current_user.authorized_projects.map { |p| { label: "project: #{simple_sanitize(p.name_with_namespace)}", url: project_path(p) } }
      groups = current_user.authorized_groups.map { |group| { label: "group: #{simple_sanitize(group.name)}", url: group_path(group) } }
      teams = current_user.authorized_teams.map { |team| { label: "team: #{simple_sanitize(team.name)}", url: team_path(team) } }
    end

    default_nav = [
      { label: "My Profile", url: profile_path },
      { label: "My SSH Keys", url: keys_path },
      { label: "My Dashboard", url: root_path },
      { label: "Admin Section", url: admin_root_path },
    ]

    help_nav = [
      { label: "help: API Help", url: help_api_path },
      { label: "help: Markdown Help", url: help_markdown_path },
      { label: "help: Permissions Help", url: help_permissions_path },
      { label: "help: Public Access Help", url: help_public_access_path },
      { label: "help: Rake Tasks Help", url: help_raketasks_path },
      { label: "help: SSH Keys Help", url: help_ssh_path },
      { label: "help: System Hooks Help", url: help_system_hooks_path },
      { label: "help: Web Hooks Help", url: help_web_hooks_path },
      { label: "help: Workflow Help", url: help_workflow_path },
    ]

    project_nav = []
    if @project && @project.repository && @project.repository.root_ref
      project_nav = [
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Issues",   url: project_issues_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Commits",  url: project_commits_path(@project, @ref || @project.repository.root_ref) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Merge Requests", url: project_merge_requests_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Milestones", url: project_milestones_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Snippets", url: project_snippets_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Team",     url: project_team_index_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Tree",     url: project_tree_path(@project, @ref || @project.repository.root_ref) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Wall",     url: project_wall_path(@project) },
        { label: "#{simple_sanitize(@project.name_with_namespace)} - Wiki",     url: project_wikis_path(@project) },
      ]
    end

    [groups, teams, projects, default_nav, project_nav, help_nav].flatten.to_json
  end

  def emoji_autocomplete_source
    # should be an array of strings
    # so to_s can be called, because it is sufficient and to_json is too slow
    Emoji.names.to_s
  end

  def omniauth_form_providers
    Gitlab.config.omniauth.form_providers
  end

  def omniauth_icon_providers
    Gitlab.config.omniauth.icon_providers
  end

  def omniauth_options(provider)
    Devise.omniauth_configs[provider].options
  end

  def omniauth_label(provider)
    configs = Devise.omniauth_configs[provider]
    name = configs.strategy_class.name.demodulize
    label = configs.options['label'] % {name: name} unless configs.options['label'].nil?
    label || name
  end

  def omniauth_title(provider)
    options = Devise.omniauth_configs[provider].options
    label = omniauth_label(provider)
    title = options['title'] % {label: label} unless options['title'].nil?
    title || "#{label} Sign in"
  end

  def app_theme
    Gitlab::Theme.css_class_by_id(current_user.try(:theme_id))
  end

  def user_color_scheme_class
    case current_user.color_scheme_id
    when 1 then 'white'
    when 2 then 'black'
    when 3 then 'solarized-dark'
    else
      'white'
    end
  end

  def show_last_push_widget?(event)
    event &&
      event.last_push_to_non_root? &&
      !event.rm_ref? &&
      event.project &&
      event.project.repository &&
      event.project.merge_requests_enabled
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def project_last_activity project
    activity = project.last_activity
    if activity && activity.created_at
      time_ago_in_words(activity.created_at) + " ago"
    else
      "Never"
    end
  end

  def authbutton(provider, size = 64)
    file_name = "#{provider.to_s.split('_').first}_#{size}.png"
    image_tag("authbuttons/#{file_name}",
              alt: "Sign in with #{provider.to_s.titleize}")
  end

  def simple_sanitize str
    sanitize(str, tags: %w(a span))
  end

  def image_url(source)
    # prevent relative_root_path being added twice (it's part of root_url and path_to_image)
    root_url.sub(/#{root_path}$/, path_to_image(source))
  end

  alias_method :url_to_image, :image_url

  def users_select_tag(id, opts = {})
    css_class = "ajax-users-select"
    css_class << " multiselect" if opts[:multiple]
    hidden_field_tag(id, '', class: css_class)
  end

  def body_data_page
    path = controller.controller_path.split('/')
    namespace = path.first if path.second

    [namespace, controller.controller_name, controller.action_name].compact.join(":")
  end

  # shortcut for gitlab config
  def gitlab_config
    Gitlab.config.gitlab
  end

  # shortcut for gitlab extra config
  def extra_config
    Gitlab.config.extra
  end

  def search_placeholder
    if @project && @project.persisted?
      "Search in this project"
    elsif @group && @group.persisted?
      "Search in this group"
    else
      "Search"
    end
  end

  def first_line(str)
    lines = str.split("\n")
    line = lines.first
    line += "..." if lines.size > 1
    line
  end

  def broadcast_message
    BroadcastMessage.current
  end

  def highlight_js(&block)
    string = capture(&block)

    content_tag :div, class: user_color_scheme_class do
      Pygments::Lexer[:js].highlight(string).html_safe
    end
  end
end
