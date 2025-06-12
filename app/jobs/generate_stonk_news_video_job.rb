# frozen_string_literal: true

require "streamio-ffmpeg"
require "open3"
require "uri"
require "net/http"

ASSETS_DIR = Rails.root.join("app", "assets", "images", "stonk_news")
IMG_SOUND  = ASSETS_DIR.join("talking.png").to_s
IMG_SILENT = ASSETS_DIR.join("idle.png").to_s

STEP       = 0.01 # seconds between frame changes
THRESHOLD  = "-15dB" # silence threshold
MINDUR     = 0.001 # minimum silence length (s)
OUTFILE    = ASSETS_DIR.join("stonk_news_#{Time.zone.now.to_i}.mp4").to_s
FRAMES_TXT = "frames.txt" # list‑file we’ll generate right here
E11_VOICE_ID = "CpgXlDvBprXc3q2PyB56"

class GenerateStonkNewsVideoJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    audio_tmp = generate_audio

    duration = FFMPEG::Movie.new(audio_tmp.path).duration
    Rails.logger.debug { "The audio is #{duration}s long" }

    silence_log, = Open3.capture2e(
      "ffmpeg", "-i", audio_tmp.path,
      "-af", "silencedetect=n=#{THRESHOLD}:d=#{MINDUR}",
      "-f", "null", "-"
    )
    silence_ranges = parse_silence_ranges(silence_log)

    frames_tmp = Tempfile.new(%w[frames_ .txt])
    build_frame_list(frames_tmp, duration, silence_ranges)
    frames_tmp.flush # make sure bytes are on disk

    system "ffmpeg", "-y",
           "-f", "concat", "-safe", "0", "-i", frames_tmp.path,
           "-vsync", "vfr",
           "-i", audio_tmp.path,
           "-c:v", "libx264", "-pix_fmt", "yuv420p",
           "-c:a", "aac",
           "-shortest",
           OUTFILE

    frames_tmp.close!
    audio_tmp.close!
  end

  private

  def generate_audio
    Rails.logger.debug "Generating report"
    raw_report = ActionController::Base.helpers.strip_tags DailyStonkReport.last.report
    report = raw_report.gsub("&nbsp;", " ").gsub("\n", ".")

    url = URI("https://api.elevenlabs.io/v1/text-to-speech/#{E11_VOICE_ID}?output_format=mp3_44100_128")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request["xi-api-key"] = ENV.fetch("E11_KEY", nil).to_s
    request.body = "{\n  \"text\": \"#{report}\",\n  \"model_id\": \"eleven_multilingual_v2\"\n}"

    Rails.logger.debug "Generating audio"
    http.request(request) do |response|
      raise "TTS failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      tmp = Tempfile.new(%w[stonk_report_ .mp3])
      tmp.binmode
      response.read_body { |chunk| tmp.write(chunk) }
      tmp.flush
      tmp.rewind
      return tmp # a Tempfile object
    end
  end

  def parse_silence_ranges(log)
    ranges = []
    start  = nil
    log.each_line do |line|
      if line[/silence_start: ([\d.]+)/]
        start = ::Regexp.last_match(1).to_f
      elsif line[/silence_end: ([\d.]+)/] && start
        ranges << (start...::Regexp.last_match(1).to_f)
        start = nil
      end
    end
    ranges
  end

  def build_frame_list(io, duration, silence_ranges)
    t = 0.0
    while t < duration
      img = silence_ranges.any? { |r| r.cover?(t) } ? IMG_SILENT : IMG_SOUND
      io.puts "file '#{img}'"
      io.puts "duration #{STEP}"
      t += STEP
    end
    io.puts "file '#{IMG_SILENT}'" # concat‑demuxer quirk
  end
end
