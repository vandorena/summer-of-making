class Mole::GuessProjectCategorizationJob < ApplicationJob
  queue_as :literally_whenever

  def perform(project_id)
    project = Project.find(project_id)

    # Skip if already categorized
    return if project.certification_type.present? && project.category.present?

    # Get project URLs
    urls = [
      project.demo_link,
      project.repo_link,
      project.readme_link
    ].reject { |c| c.empty? }.compact.uniq

    Rails.logger.info "Project #{project_id} URLs: #{urls.join(', ')}"

    # Skip if no URLs to analyze
    return if urls.empty?

    # Classification prompt
    task_prompt = build_classification_prompt

    # Call mole browser service
    mole_service = MoleBrowserService.new
    response = mole_service.execute_task(task_prompt, urls)

    if response[:success] && response[:result]
      update_project_classification(project, response[:result])

      # Log the GIF URL if available
      if response[:gif_url].present?
        Rails.logger.info "Project #{project_id} classification GIF: #{response[:gif_url]}"
      end
    else
      Rails.logger.error "Failed to classify project #{project_id}: #{response[:error]}"
    end
  end

  private

  def build_classification_prompt
    cert_types = Project.certification_types.keys

    <<~PROMPT
      You are helping a hackathon project reviewer for an adventure-themed hackathon. You are a mascot mole, the thing that digs in the dirt and can't see well.

      Analyze this project to classify how it can be tested on the provided URLs (README, demo/play link, and repository).

      Visit these links and determine a classification: #{cert_types.join(', ')}
      If you are already sure, you don't need to visit every link. For example, if a release includes an APK file, you can skip the demo/play link.
      If you are low confidence, or the main categories don't seem to fit, return "cert_other".
      Projects that can't be used as an app (ie. a research paper isn't runable, ipynotebook etc.) should be "cert_other".
      Projects that use a video as their demo link should be classified as video.

      If it helps, you can visualize the filetree using https://githubtree.mgks.dev/ (for example, https://githubtree.mgks.dev/repo/hackclub/site/main/)

      Base your decision on:
      - Code in the repository (languages, frameworks, dependencies)
      - Demo/play functionality if available
      - README description and documentation
      - Project structure and build files

      Your decision is based on how to test the app- for example, a pygame app without an executable would be a command_line app. A pygame with an executable would be a desktop_app.

      Return your classification in this EXACT format:
      CERT_TYPE|CONFIDENCE|REASONING

      Where:
      - CERT_TYPE is one of: #{cert_types.join(', ')}
      - CONFIDENCE is a number between 0 and 1 (e.g., 0.95)
      - REASONING is a brief explanation of why you chose this classification. 1 sentence tops. No yapping.

      Examples:
      web_app|0.85|Uses React framework with API calls and deployment to Vercel
      static_site|0.9|This is a github.io link, so it's hosted on github pages
      cert_other|0.1|This is a repo of only markdown files so it's not clear how to test this

      Return ONLY this pipe-separated format. No other text.
    PROMPT
  end



  def update_project_classification(project, result)
    # Parse pipe-separated result: CERT_TYPE|CONFIDENCE|REASONING
    if result.is_a?(String)
      parts = result.strip.split("|", 3)
      if parts.length >= 3
        cert_type = parts[0].strip
        confidence = parts[1].strip.to_f
        reasoning = parts[2].strip

        Rails.logger.info "Parsed classification: #{cert_type} (confidence: #{confidence}) - #{reasoning}"

        # Update project with classification
        project.update!(
          certification_type: cert_type
        )

        Rails.logger.info "Updated project #{project.id} classification: #{cert_type}"
      else
        Rails.logger.error "Invalid pipe-separated format: #{result}"
      end
    else
      Rails.logger.error "Expected string result, got #{result.class}: #{result}"
    end
  rescue => e
    Rails.logger.error "Failed to update project #{project.id} classification: #{e.message}"
  end
end
