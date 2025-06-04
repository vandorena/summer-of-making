require "open-uri"

class LandingController < ApplicationController
  def index
    redirect_to explore_path if user_signed_in?
    @prizes = [
      {
        name: "Flipper Zero",
        cost: 120,
        time: "~120 hours",
        image: nil
      },
      {
        name: "Framework Laptop DIY Edition",
        cost: 800,
        time: "~800 hours",
        image: nil
      },
      {
        name: "Pinecil Soldering Iron",
        cost: 30,
        time: "~30 hours",
        image: nil
      },
      {
        name: "Cloud Credits - Cloudflare",
        cost: 50,
        time: "~50 hours",
        image: nil
      },
      {
        name: "PCB Credits - JLCPCB",
        cost: 30,
        time: "~30 hours",
        image: nil
      },
      {
        name: "iPad with Apple Pencil",
        cost: 450,
        time: "~450 hours",
        image: nil
      },
      {
        name: "Raspberry Pi 5 Starter Kit",
        cost: 90,
        time: "~90 hours",
        image: nil
      },
      {
        name: "BLÅHAJ Soft Toy",
        cost: 20,
        time: "~20 hours",
        image: nil
      },
      {
        name: "Sony WH-1000XM4 Headphones",
        cost: 250,
        time: "~250 hours",
        image: nil
      },
      {
        name: "Steam Game - Factorio",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "Ben Eater 8-bit Computer Kit",
        cost: 200,
        time: "~200 hours",
        image: nil
      },
      {
        name: "MORE FUDGE!",
        cost: 35,
        time: "~35 hours",
        image: nil
      }
    ]
  end

  def sign_up
    email = params.require(:email)

    ip = request.remote_ip
    ip_response_raw = URI.open("https://ip.hackclub.com/ip/#{ip}").read
    if ip_response_raw.presence
      ip_response = JSON.parse(ip_response_raw)
      continent = ip_response["continent_name"] || ip_response["continent_code"] || "?"
    else
      continent = "?"
    end

    uri = URI("https://toriel.hackclub.com/slack-invite")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{Rails.application.credentials.toriel_key}"
    request.body = { email:, ip:, continent:, event: "Summer of Making 2025", userAgent: "som25server(landing_controller#sign_up)" }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    puts "Status: #{response.code}"
    puts "Body:\n#{response.body}"

    body = JSON.parse(response.body)
    puts body

    respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # ① append the modal itself
            turbo_stream.append(
              "modals",
              partial: "landing/signup_modal",
              locals:  { api_body: body }
            ),

            # ② immediately append a <script> tag that opens it
            turbo_stream.append(
              "modals",
              helpers.tag.script(
                "document.dispatchEvent(new Event('open-signup-modal'))".html_safe
              )
            )
          ]
        end
      end
  end
end
