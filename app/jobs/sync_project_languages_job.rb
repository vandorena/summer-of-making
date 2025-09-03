class SyncProjectLanguagesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting ProjectLanguages sync job"

    # Find projects that need language syncing using the scope
    projects_to_sync = Project.needs_language_sync.limit(10)

    Rails.logger.info "Found #{projects_to_sync.count} projects to sync"

    projects_to_sync.find_each do |project|
      sync_project_languages(project)
    rescue StandardError => e
      Rails.logger.error "Failed to sync languages for project #{project.id}: #{e.message}"
    end

    Rails.logger.info "Completed ProjectLanguages sync job"
  end

  private

  def sync_project_languages(project)
    return unless project.repo_link.present?

    owner, repo = extract_github_info(project.repo_link)
    return unless owner && repo

    # Find or create ProjectLanguage record
    project_language = ProjectLanguage.find_or_create_by(project: project) do |pl|
      pl.status = :pending
      pl.language_stats = {}
    end

    begin
      github_service = GithubProxyService.new
      language_stats = github_service.get_repository_languages(owner, repo)

      project_language.mark_sync_success!(language_stats)
      Rails.logger.info "Successfully synced languages for project #{project.id}: #{language_stats.keys.join(', ')}"
    rescue GithubProxyService::GithubProxyError => e
      project_language.mark_sync_failed!(e.message)
      Rails.logger.warn "GitHub API error for project #{project.id}: #{e.message}"
    rescue StandardError => e
      project_language.mark_sync_failed!(e.message)
      Rails.logger.error "Unexpected error syncing project #{project.id}: #{e.message}"
      raise e
    end
  end

  def extract_github_info(repo_link)
    return nil unless repo_link.present?

    # Handle various GitHub URL formats
    uri = URI.parse(repo_link.strip)
    path = uri.path.sub(/^\//, "").sub(/\.git$/, "").split("/")

    return nil unless path.length >= 2

    owner = path[0]
    repo = path[1]

    return nil if owner.blank? || repo.blank?

    [ owner, repo ]
  rescue URI::InvalidURIError
    Rails.logger.warn "Invalid repo URL format: #{repo_link}"
    nil
  end
end
