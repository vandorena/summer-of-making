class Mole::BrowserTestJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting browser test job"

    task_prompt = "Go to Google and search for 'today's weather'. Tell me what the current weather is like."
    urls = []

    # Use the MoleBrowserService to execute the task
    mole_service = MoleBrowserService.new
    result = mole_service.execute_task(task_prompt, urls)

    if result["success"]
      Rails.logger.info "Browser test completed successfully: #{result["result"]}"
      puts "\n=== BROWSER TEST RESULT ==="
      puts result["result"]
      puts "=========================="

      if result["gif_url"]
        puts "GIF available at: #{result["gif_url"]}"
      end
    else
      Rails.logger.error "Browser test failed: #{result["error"]}"
      puts "Browser test failed: #{result["error"] || 'Unknown error'}"
      puts "Full result: #{result.inspect}"
    end

    result
  end
end
