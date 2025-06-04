require "open-uri"

class LandingController < ApplicationController
  def index
    redirect_to explore_path if user_signed_in?
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
