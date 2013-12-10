class ProjectsController < ProjectResourceController
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :project, except: [:new, :create]
  before_filter :repository, except: [:new, :create]
 # skip_before_filter :project, only: [:new, :create]
 # skip_before_filter :repository, only: [:new, :create]

  # Authorize
  before_filter :authorize_read_project!, except: [:index, :new, :create]
  before_filter :authorize_admin_project!, only: [:edit, :update, :destroy, :transfer]
  before_filter :require_non_empty_project, only: [:blob, :tree, :graph]

  layout 'application', only: [:new, :create]

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = ::Projects::CreateContext.new(current_user, params[:project]).execute

    respond_to do |format|
      flash[:notice] = 'Project was successfully created.' if @project.saved?
      format.html do
        if @project.saved?
          redirect_to @project
        else
          render action: "new"
        end
      end
      format.js
    end
  end

  def update
    status = ::Projects::UpdateContext.new(project, current_user, params).execute

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to edit_project_path(project), notice: 'Project was successfully updated.' }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end
  end

  def transfer
    ::Projects::TransferContext.new(project, current_user, params).execute
  end

  def show
    return authenticate_user! unless @project.public? || current_user

#    limit = (params[:limit] || 20).to_i
#    @events = @project.events.recent
##    @events = event_filter.apply_filter(@events)
#    @events = @events.limit(limit).offset(params[:offset] || 0)
#
#    respond_to do |format|
#      format.html do
#        if @project.empty_repo?
#          render "projects/empty", layout: user_layout
#        else
#          if current_user
#            @last_push = current_user.recent_push(@project.id)
#          end
#          render :show, layout: user_layout
#        end
#      end
#      format.json { pager_json("events/_events", @events.count) }
#    end
#  end
#
    limit = (params[:limit] || 20).to_i
    @events = @project.events.recent.limit(limit).offset(params[:offset] || 0)

    respond_to do |format|
      format.html do
        if @project.repository && !@project.repository.empty?
          if current_user
            @last_push = current_user.recent_push(@project.id)
          end
          render :show
        else
          render "projects/empty"
        end
      end
      format.js
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    project.team.truncate
    project.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end
end
