# frozen_string_literal: true

class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  safelist_ip("127.0.0.1")
  safelist_ip("::1")

  blocklist("block bad user agents") do |req|
    bad_agents = [
      /bot/i,
      /crawler/i,
      /spider/i,
      /scraper/i,
      /openai/i,
      /gpt/i,
      /claude/i,
      /anthropic/i,
      /chatgpt/i,
      /bard/i,
      /gemini/i,
      /perplexity/i,
      /llm/i,
      /ai/i,
      /node-fetch/i,
      /axios/i,
      /undici/i,
      /node\.js/i,
      /nodejs/i,
      /node/i,
      /curl/i,
      /wget/i,
      /python-requests/i,
      /python-urllib/i,
      /go-http-client/i,
      /java/i,
      /okhttp/i,
      /apache-httpclient/i,
      /postman/i,
      /insomnia/i,
      /facebookexternalhit/i,
      /twitterbot/i,
      /linkedinbot/i,
      /ahrefsbot/i,
      /semrushbot/i,
      /mj12bot/i,
      /dotbot/i,
      /rogerbot/i,
      # Generic patterns
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

  throttle("requests by IP", limit: 50, period: 1.second) do |req|
    req.ip
  end

  throttle("requests by IP per minute", limit: 3000, period: 1.minute) do |req|
    req.ip
  end

  throttle("login attempts by IP", limit: 10, period: 1.minute) do |req|
    if req.path.match?(/\A\/auth(\/.*)?\z/i) && req.post?
      req.ip
    end
  end

  throttle("api requests by IP", limit: 100, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  self.blocklisted_responder = lambda do |env|
    [
      403,
      { "Content-Type" => "text/plain" },
      [ "stinky butt\n" ]
    ]
  end

  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    retry_after = match_data.is_a?(Hash) ? match_data[:period] : 60
    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => retry_after.to_s
      },
      [ "ur going too fast, slow down bucko\n" ]
    ]
  end

  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    case req.env["rack.attack.match_type"]
    when :throttle
      Rails.logger.warn "[Rack::Attack] Throttled #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath}"
    when :blocklist
      Rails.logger.warn "[Rack::Attack] Blocked #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath} User-Agent: #{req.user_agent}"
    when :safelist
      Rails.logger.info "[Rack::Attack] Safelisted #{req.env['rack.attack.matched']} #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end
