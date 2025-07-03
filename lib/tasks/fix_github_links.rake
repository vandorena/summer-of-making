# frozen_string_literal: true

namespace :projects do
  desc "unfuck github urls"
  task fix_github_links: :environment do
    updated_count = 0
    total_projects = Project.count

    Project.find_each.with_index do |project, index|
      puts "peeking at #{index + 1}/#{total_projects}: #{project.title}" if (index + 1) % 100 == 0

      if project.readme_link.present?
        converted_readme = Project.convert_github_blob_to_raw(project.readme_link)
        if converted_readme != project.readme_link
          puts "fixing #{project.readme_link} -> #{converted_readme}"
          project.update_column(:readme_link, converted_readme)
          updated_count += 1
        end
      end

      if project.repo_link.present? && project.readme_link.blank?
        converted_repo = Project.convert_github_blob_to_raw(project.repo_link)
        if converted_repo != project.repo_link && converted_repo.include?("raw.githubusercontent.com")
          puts "fixing #{project.repo_link} -> #{converted_repo}"
          project.update_columns(readme_link: converted_repo)
          updated_count += 1
        end
      end
    end

    puts "fixed #{updated_count} projects with politically correct GitHub links"
  end
end
