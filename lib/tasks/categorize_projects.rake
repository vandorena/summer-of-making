namespace :projects do
  desc "Test browser automation with a simple Google weather task"
  task test_browser: :environment do
    puts "Running browser test..."
    result = Mole::BrowserTestJob.perform_now

    if result[:success]
      puts "Browser test completed successfully!"
    else
      puts "Browser test failed: #{result[:error]}"
    end
  end

  desc "Batch categorize uncategorized projects"
  task :batch_categorize, [ :count ] => :environment do |_task, args|
    count = (args[:count] || 20).to_i

    # Find projects with ship events that are missing certification_type
    uncategorized_projects = Project.joins(:ship_events)
      .where(certification_type: [ nil, "" ])
      .distinct
      .limit(count)

    if uncategorized_projects.empty?
      puts "No uncategorized projects found"
      exit
    end

    project_ids = uncategorized_projects.pluck(:id)
    puts "Found #{project_ids.length} uncategorized projects to process"
    puts "Project IDs: #{project_ids.join(', ')}"

    # Run batch job immediately
    puts "Starting batch categorization..."
    Mole::BatchGuessProjectCategorizationJob.perform_now(project_ids)

    puts "Batch categorization completed!"
  end

  desc "Categorize specific projects by ID"
  task :categorize_by_ids, [ :ids ] => :environment do |_task, args|
    unless args[:ids]
      puts "Usage: rake projects:categorize_by_ids[1,2,3,4]"
      exit
    end

    project_ids = args[:ids].split(",").map(&:to_i)

    # Validate projects exist
    existing_projects = Project.where(id: project_ids)
    if existing_projects.count != project_ids.length
      missing_ids = project_ids - existing_projects.pluck(:id)
      puts "Warning: Projects not found: #{missing_ids.join(', ')}" if missing_ids.any?
    end

    if existing_projects.empty?
      puts "No valid projects found"
      exit
    end

    puts "Categorizing #{existing_projects.count} projects: #{existing_projects.pluck(:id).join(', ')}"

    # Run batch job immediately
    Mole::BatchGuessProjectCategorizationJob.perform_now(existing_projects.pluck(:id))

    puts "Batch categorization completed!"
  end

  desc "Show categorization status"
  task categorization_status: :environment do
    total = Project.count
    categorized = Project.where.not(certification_type: [ nil, "" ]).count
    uncategorized = total - categorized

    puts "Project Categorization Status:"
    puts "Total projects: #{total}"
    puts "Categorized: #{categorized}"
    puts "Uncategorized: #{uncategorized}"
    puts "Progress: #{((categorized.to_f / total) * 100).round(1)}%"

    if uncategorized > 0
      puts "\nNext #{[ uncategorized, 20 ].min} uncategorized project IDs (with ship events):"
      next_batch = Project.joins(:ship_events)
        .where(certification_type: [ nil, "" ])
        .distinct
        .limit(20)
        .pluck(:id)
      puts next_batch.join(", ")
    end
  end
end
