# frozen_string_literal: true

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
        name: "3D Printer Filament Bundle",
        cost: 40,
        time: "~40 hours",
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
        name: "Cloud Credits - GitHub Codespaces",
        cost: 75,
        time: "~75 hours",
        image: nil
      },
      {
        name: "Cloud Credits - DigitalOcean",
        cost: 60,
        time: "~60 hours",
        image: nil
      },
      {
        name: "PCB Credits - JLCPCB",
        cost: 30,
        time: "~30 hours",
        image: nil
      },
      {
        name: "Electronics Credits - Digikey",
        cost: 80,
        time: "~80 hours",
        image: nil
      },
      {
        name: "Domain Registration Credits",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "iPad with Apple Pencil",
        cost: 450,
        time: "~450 hours",
        image: nil
      },
      {
        name: "Mode Design Sonnet Keyboard",
        cost: 300,
        time: "~300 hours",
        image: nil
      },
      {
        name: "Ben Eater 8-bit Computer Kit",
        cost: 200,
        time: "~200 hours",
        image: nil
      },
      {
        name: "Raspberry Pi 5 Starter Kit",
        cost: 90,
        time: "~90 hours",
        image: nil
      },
      {
        name: "Raspberry Pi Zero 2 W",
        cost: 35,
        time: "~35 hours",
        image: nil
      },
      {
        name: "ThinkPad X1 Carbon (Refurbished)",
        cost: 600,
        time: "~600 hours",
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
        name: "Bose QuietComfort 45",
        cost: 280,
        time: "~280 hours",
        image: nil
      },
      {
        name: "Logitech MX Master 3S Mouse",
        cost: 80,
        time: "~80 hours",
        image: nil
      },
      {
        name: "Logitech Pro X Superlight Mouse",
        cost: 150,
        time: "~150 hours",
        image: nil
      },
      {
        name: "Steam Game - Factorio",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "Steam Game - Satisfactory",
        cost: 30,
        time: "~30 hours",
        image: nil
      },
      {
        name: "Cricut Explore 3",
        cost: 180,
        time: "~180 hours",
        image: nil
      },
      {
        name: "MORE FUDGE!",
        cost: 35,
        time: "~35 hours",
        image: nil
      },
      {
        name: "Hack Club Merch Bundle",
        cost: 50,
        time: "~50 hours",
        image: nil
      },
      {
        name: "Hack Club Sticker Pack",
        cost: 10,
        time: "~10 hours",
        image: nil
      },
      {
        name: "Signed Photo of Zack Latta",
        cost: 100,
        time: "~100 hours",
        image: nil
      },
      {
        name: "Personal Drawing from MSW",
        cost: 200,
        time: "~200 hours",
        image: nil
      },
      {
        name: "Random Object from HQ",
        cost: 15,
        time: "~15 hours",
        image: nil
      },
      {
        name: "Bottom Half of Chromebook",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "Mystery eBay Treasure",
        cost: 30,
        time: "~30 hours",
        image: nil
      },
      {
        name: "Top Half of Chromebook",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "Bottom Half of Chromebook",
        cost: 30,
        time: "~30 hours",
        image: nil
      }
    ]
  end

  def sign_up
    email = params.require(:email)

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return respond_to do |format|
        format.html { redirect_to request.referer || projects_path, alert: "Invalid email format" }
        format.turbo_stream do
          flash.now[:alert] = "Invalid email format"
          render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash"),
                 status: :internal_server_error
        end
      end
    end

    EmailSignup.create!(email:)

    slack_invite_response = send_slack_invite(email)

    Rails.logger.debug { "Status: #{slack_invite_response.code}" }
    Rails.logger.debug { "Body:\n#{slack_invite_response.body}" }

    body = JSON.parse(slack_invite_response.body)
    Rails.logger.debug body

    @response_data = body

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("modal-content", partial: "landing/signup_modal"),
          turbo_stream.action("show_modal", "signup-modal")
        ]
      end
    end
  end

  private

  def send_slack_invite(email)
    ip = request.remote_ip
    continent = fetch_continent(ip)

    uri = URI("https://toriel.hackclub.com/slack-invite")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{Rails.application.credentials.toriel_key}"
    request.body = {
      email:,
      ip:,
      continent:,
      event: "Summer of Making 2025",
      userAgent: "som25server(landing_controller#sign_up)"
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end

  def fetch_continent(ip)
    response = URI.open("https://ip.hackclub.com/ip/#{ip}").read
    return "?" if response.blank?

    data = JSON.parse(response)
    data["continent_name"] || data["continent_code"] || "?"
  rescue StandardError => e
    Rails.logger.error "IP lookup failed: #{e.message}"
    "?"
  end
end
