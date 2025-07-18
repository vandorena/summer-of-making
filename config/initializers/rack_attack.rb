# frozen_string_literal: true

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  safelist_ip("127.0.0.1")
  safelist_ip("::1")

  blocklist("block ai and node bots") do |req|
    bad_agents = [
      # AI bots
      /openai/i,
      /gpt/i,
      /claude/i,
      /anthropic/i,
      /chatgpt/i,
      /bard/i,
      /gemini/i,
      /perplexity/i,
      /llm/i,
      /node-fetch/i,
      /axios/i,
      /undici/i,
      /node\.js/i,
      /nodejs/i,
      /node/i,
      /curl/i,
      /wget/i,
      /headless/i,
      /phantom/i,
      /selenium/i,
      /puppeteer/i,
      /playwright/i
    ]

    user_agent = req.user_agent.to_s
    bad_agents.any? { |pattern| user_agent.match?(pattern) }
  end

  safelist("allow search engines") do |req|
    cool = [
      /googlebot/i,
      /bingbot/i,
      /slurp/i, # how tf is this yahoo
      /duckduckbot/i,
      /baiduspider/i,
      /yandexbot/i
    ]

    user_agent = req.user_agent.to_s
    cool.any? { |pattern| user_agent.match?(pattern) }
  end

  self.blocklisted_responder = lambda do |env|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { ok: false, message: "get blocked nerd" }.to_json ]
    ]
  end

  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    case req.env["rack.attack.match_type"]
    when :blocklist
      Rails.logger.warn "[Rack::Attack] Blocked #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath} User-Agent: #{req.user_agent}"
    when :safelist
      Rails.logger.info "[Rack::Attack] Safelisted #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end
