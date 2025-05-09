class ProjectsController < ApplicationController
    include ActionView::RecordIdentifier
    before_action :authenticate_user!
    before_action :set_project, only: [ :show, :edit, :update, :follow, :unfollow, :ship ]
    before_action :check_if_shipped, only: [ :edit, :update ]

    def index
        @projects = Project.includes(:user)
                          .where.not(user_id: current_user.id)
                          .order(rating: :asc)

        @projects = @projects.sort_by do |project|
            weight = rand + (project.updates.count > 0 ? 1.5 : 0)
            -weight
        end

        if params[:action] == "my_projects" && @projects.empty?
            @show_create_project = true
        end
    end

    def show
        @updates = @project.updates.order(created_at: :asc)
    end

    def edit
        unless current_user == @project.user
            redirect_to project_path(@project), alert: "You can only edit your own projects."
        end
    end

    def update
        if current_user == @project.user
            if @project.update(project_params)
                redirect_to project_path(@project), notice: "Project was successfully updated."
            else
                render :edit, status: :unprocessable_entity
            end
        else
            redirect_to project_path(@project), alert: "Something went wrong. Please try again."
        end
    end

    def create
        @project = current_user.projects.build(project_params)

        if @project.save
            redirect_to project_path(@project), notice: "Project was successfully created."
        else
            flash.now[:alert] = "Could not create project. Please check the form for errors."
            render :index, status: :unprocessable_entity
        end
    end

    def my_projects
        @projects = current_user.projects.order(created_at: :desc)
        @show_create_project = true
        render :index
    end

    def activity
        @followed_projects = current_user.followed_projects.includes(:user)
        @recent_updates = Update.includes(:project, :user)
                              .where(project_id: @followed_projects.pluck(:id))
                              .order(created_at: :desc)
    end

    # Gotta say I love turbo frames and turbo streams and flashes in general
    def follow
        if current_user == @project.user
            respond_to do |format|
                format.html { redirect_to request.referer || projects_path, alert: "You cannot follow your own project" }
                format.turbo_stream do
                    flash.now[:alert] = "You cannot follow your own project"
                    render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash")
                end
            end
            return
        end

        @project_follow = current_user.project_follows.build(project: @project)

        respond_to do |format|
            if @project_follow.save
                message = "Well, would you look at that! 💅 You've got a brand new follower on your project: *#{@project.title}*! :ultrafastparrot:"
                SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?

                format.html { redirect_to request.referer || projects_path, notice: "You are now following this project!" }
                format.turbo_stream do
                    flash.now[:notice] = "You are now following this project!"
                    render turbo_stream: [
                        turbo_stream.update("flash-container", partial: "shared/flash"),
                        turbo_stream.replace(dom_id(@project, :follow_button),
                            partial: "projects/follow_button",
                            locals: { project: @project, following: true }
                        )
                    ]
                end
            else
                error_message = @project_follow.errors.full_messages.join(", ")
                format.html { redirect_to request.referer || projects_path, alert: "Could not follow project: #{error_message}" }
                format.turbo_stream do
                    flash.now[:alert] = "Could not follow project: #{error_message}"
                    render turbo_stream: [
                        turbo_stream.update("flash-container", partial: "shared/flash"),
                        turbo_stream.replace(dom_id(@project, :follow_button),
                            partial: "projects/follow_button",
                            locals: { project: @project, following: false }
                        )
                    ]
                end
            end
        end
    end

    def unfollow
        @project_follow = current_user.project_follows.find_by(project: @project)

        respond_to do |format|
            if @project_follow&.destroy
                format.html { redirect_to request.referer || projects_path, notice: "You have unfollowed this project." }
                format.turbo_stream do
                    flash.now[:notice] = "You have unfollowed this project."
                    render turbo_stream: [
                        turbo_stream.update("flash-container", partial: "shared/flash"),
                        turbo_stream.replace(dom_id(@project, :follow_button),
                            partial: "projects/follow_button",
                            locals: { project: @project, following: false }
                        )
                    ]
                end
            else
                format.html { redirect_to request.referer || projects_path, alert: "Could not unfollow project." }
                format.turbo_stream do
                    flash.now[:alert] = "Could not unfollow project."
                    render turbo_stream: [
                        turbo_stream.update("flash-container", partial: "shared/flash"),
                        turbo_stream.replace(dom_id(@project, :follow_button),
                            partial: "projects/follow_button",
                            locals: { project: @project, following: true }
                        )
                    ]
                end
            end
        end
    end

    def ship
        unless current_user == @project.user
            respond_to do |format|
                format.html { redirect_to project_path(@project), alert: "You can only ship your own project." }
                format.turbo_stream do
                    flash.now[:alert] = "You can only ship your own project."
                    render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash")
                end
            end
            return
        end

        # Verify all requirements are met
        errors = []

        if @project.updates.count < 10
            errors << "Project must have at least 10 updates."
        end

        unique_dates = @project.updates.pluck(:created_at).compact.map { |date| date.to_date }.uniq
        if unique_dates.count < 5
            errors << "Updates must be posted on at least 5 different dates."
        end

        if @project.repo_link.blank?
            errors << "Project must have a repository link."
        end

        if @project.readme_link.blank? || !@project.readme_link.include?("raw")
            errors << "Project must have a raw GitHub documentation link."
        end

        if @project.demo_link.blank?
            errors << "Project must have a demo link."
        end

        if @project.description.blank? || @project.description.length < 30
            errors << "Project must have a valid description (at least 30 characters)."
        end

        if @project.banner.blank?
            errors << "Project must have a banner image."
        end

        if errors.any?
            redirect_to project_path(@project), alert: "Cannot ship project: #{errors.join(' ')}"
            return
        end
        if @project.update(is_shipped: true)
            redirect_to project_path(@project), notice: "Your project has been shipped!"

            message = "Congratulations on shipping your project! Now thy project shall fight for blood :ultrafastparrot:"
            SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?
        else
            redirect_to project_path(@project), alert: "Could not ship project."
        end
    end

    # Some AI generated code to check if a link is a valid repo or readme link
    def check_link
        url = params[:url]
        link_type = params[:link_type]

        require "net/http"
        require "uri"

        begin
            uri = URI.parse(url)
            # Really, just trying to check if it's a valid repo or readme link and not some random link
            if [ "repo", "readme" ].include?(link_type)
                repo_patterns = [
                    %r{/blob/}, %r{/tree/}, %r{/src/}, %r{/raw/}, %r{/commits/},
                    %r{/pull/}, %r{/issues/}, %r{/compare/}, %r{/releases/},
                    %r{\.git$}, %r{/commit/}, %r{/branch/}, %r{/blame/},

                    %r{/projects/}, %r{/repositories/}, %r{/gitea/}, %r{/cgit/},
                    %r{/gitweb/}, %r{/gogs/}, %r{/git/}, %r{/scm/},

                    %r{\.(md|py|js|ts|jsx|tsx|html|css|scss|php|rb|go|rs|java|cpp|c|h|cs|swift)$}
                ]

                # Known code hosting platforms (not required, but used for heuristic)
                known_platforms = [
                    "github", "gitlab", "bitbucket", "dev.azure", "sourceforge",
                    "codeberg", "sr.ht", "replit", "vercel", "netlify", "glitch",
                    "hackclub", "gitea", "git", "repo", "code"
                ]

                path = uri.path.downcase
                host = uri.host.downcase
                full_url = url.downcase

                is_valid_repo_url = false

                if repo_patterns.any? { |pattern| path.match?(pattern) }
                    is_valid_repo_url = true
                elsif link_type == "readme" && (host.include?("raw.githubusercontent") || path.include?("/readme") || path.end_with?(".md") || path.end_with?("readme.txt"))
                    is_valid_repo_url = true
                elsif known_platforms.any? { |platform| host.include?(platform) }
                    is_valid_repo_url = path.split("/").size > 2
                elsif path.split("/").size > 1 && !path.include?("wp-") && !path.include?("blog")
                    is_valid_repo_url = true
                end

                unless is_valid_repo_url
                    error_message = if link_type == "repo"
                        "This doesn't appear to be a valid code repository URL. Please use a link to a repository structure."
                    else
                        "This doesn't appear to be a valid documentation URL. Please use a link to a README file or documentation."
                    end

                    render json: { valid: false, error: error_message }
                    return
                end
            end

            response = nil

            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
                request = Net::HTTP::Head.new(uri)
                request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
                response = http.request(request)

                if response.code.to_i >= 300 && response.code.to_i < 400 && response["location"]
                    redirect_uri = URI.parse(response["location"])
                    redirect_uri = URI.join(uri.to_s, response["location"]) if redirect_uri.host.nil?

                    redirect_request = Net::HTTP::Head.new(redirect_uri)
                    redirect_request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"

                    Net::HTTP.start(redirect_uri.host, redirect_uri.port, use_ssl: redirect_uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |redirect_http|
                        response = redirect_http.request(redirect_request)
                    end
                end
            end

            case response.code.to_i
            when 200..299
                render json: { valid: true }
            when 401, 403
                domain = uri.host
                auth_message = case domain
                when /github\.com/
                                  "This GitHub repo appears to be private. Please make it public or choose a different repo."
                when /gitlab\.com/
                                  "This GitLab repo appears to be private. Please make it public or choose a different repo."
                else
                                  "This link requires authentication. Please make sure it's publicly accessible."
                end
                render json: { valid: false, error: auth_message }
            when 404
                render json: { valid: false, error: "URL not found (404). Please check the link." }
            when 429
                render json: { valid: false, error: "Rate limited by the server. Try again later." }
            when 500..599
                render json: { valid: false, error: "Server error (#{response.code}). The site might be down." }
            else
                render json: { valid: false, error: "Returned status code #{response.code}" }
            end
        rescue URI::InvalidURIError
            render json: { valid: false, error: "Invalid URL format. Please check the URL." }
        rescue Errno::ECONNREFUSED
            render json: { valid: false, error: "Connection refused. The server might be down." }
        rescue Net::OpenTimeout
            render json: { valid: false, error: "Connection timed out. The server might be slow or down." }
        rescue StandardError => e
            render json: { valid: false, error: e.message }
        end
    end

    private

    def set_project
        @project = Project.includes(:user, updates: :user).find(params[:id])
    end

    def check_if_shipped
        if @project.is_shipped?
            redirect_to project_path(@project), alert: "This project has been shipped and cannot be edited."
        end
    end

    def project_params
        params.require(:project).permit(:title, :description, :readme_link, :demo_link, :repo_link, :banner, :category)
    end
end
