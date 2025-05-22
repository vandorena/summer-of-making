require "json"
require "openai"

class GenerateStonkReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    stonks_data = Stonk.report

    prompt = <<~PROMPT
    **Role**: You are “The Exchange Desk”, an objective financial‑markets analyst.
    **Audience**: Investors tracking the Hack Club Stonks exchange.
    **Task**: Write a 250‑to‑300‑word end‑of‑day market report (UTC) covering the last 24 hours only.

    In the following JSON:
    Outer keys = [title, description, category, is_shipped, rating, project_created_at].
    Inner keys = day_bucket where 0 is the last 24h, 1 is 24‑48h ago, etc.
    Inner values = the sum of stonks created only during that bucket — they are not cumulative totals.

    How to use it:
    Focus on bucket 0 totals to determine today’s gainers / losers.
    Rank projects by today’s stonk amount; highlight the top 3 movers.
    Summarize overall market tone (bullish / bearish / mixed) and any notable sector trends (e.g., “Both Software & Hardware” vs. “Software”).
    Include a brief note on investor sentiment (e.g., “risk‑on appetite returns”, “profit‑taking in legacy categories”).
    Where useful, reference yesterday’s bucket 1 totals to frame percentage or absolute changes.
    Close with an outlook for the next trading session in one sentence.

    Style guide:
    Professional, finance‑desk tone (think Bloomberg or Financial Times).
    Use active voice, concise sentences, and specific numbers (“Hackatime led with 36 stonks, up 20% from yesterday”).
    No first‑person; write in the third person.
    Do not list every project—aggregate or pick exemplars unless they are major movers.
    PROMPT

    OpenAI.configure { |c| c.access_token = ENV.fetch("OPENAI_KEY") }
    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "o3",
        messages: [
          { role: "system", content: prompt },
          { role: "user", content: stonks_data }
        ]
      }
    )

    report = response.dig("choices", 0, "message", "content")
  end
end
