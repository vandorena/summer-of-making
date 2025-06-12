# frozen_string_literal: true

class GroqService
  class InferenceError < StandardError; end

  API_URL = "https://api.groq.com/openai/v1/chat/completions"
  DEFAULT_MODEL = "llama-3.1-8b-instant"

  def self.call(prompt, model: DEFAULT_MODEL)
    messages = [ { role: "user", content: prompt } ]

    response = Faraday.post(API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        messages: messages,
        model: model,
        temperature: 0.1,
        max_tokens: 1000
      }.to_json
    end

    if response.success?
      data = JSON.parse(response.body)
      content = data.dig("choices", 0, "message", "content")

      if content.present?
        content.strip
      else
        raise InferenceError, "No content in response"
      end
    else
      raise InferenceError, "API request failed: #{response.status} - #{response.body}"
    end
  rescue JSON::ParserError => e
    raise InferenceError, "Failed to parse response: #{e.message}"
  rescue StandardError => e
    raise InferenceError, "Request failed: #{e.message}"
  end

  def self.completion(prompt, model: DEFAULT_MODEL)
    call(prompt, model: model)
  end
end
