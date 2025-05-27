require "streamio-ffmpeg"
require "open3"

AUDIO      = "track.mp3"            # your audio track
IMG_SOUND  = "talking.png"             # frame when sound is present
IMG_SILENT = "idle.png"             # frame when silent
STEP       = 0.01                    # seconds between frame changes
THRESHOLD  = "-15dB"                # silence threshold
MINDUR     = 0.001                    # minimum silence length (s)
OUTFILE    = "output.mp4"
FRAMES_TXT = "frames.txt"           # list‑file we’ll generate right here

class GenerateStonkNewsVideoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # ---------- 1. Duration ----------------------------------------------------
    duration = FFMPEG::Movie.new(AUDIO).duration

    # ---------- 2. Detect silence ---------------------------------------------
    silence_log, _ = Open3.capture2e(
      "ffmpeg", "-i", AUDIO,
      "-af", "silencedetect=n=#{THRESHOLD}:d=#{MINDUR}",
      "-f", "null", "-"
    )

    silence_ranges = []
    start = nil
    silence_log.each_line do |line|
      if line[/silence_start: ([\d.]+)/]
        start = $1.to_f
      elsif line[/silence_end: ([\d.]+)/] && start
        silence_ranges << (start...$1.to_f)
        start = nil
      end
    end

    def silent_at?(t, ranges)
      ranges.any? { |r| r.cover?(t) }
    end

    # ---------- 3. Build frames.txt right here ---------------------------------
    File.open(FRAMES_TXT, "w") do |f|
      t = 0.0
      while t < duration
        img = silent_at?(t, silence_ranges) ? IMG_SILENT : IMG_SOUND
        f.puts "file '#{img}'"
        f.puts "duration #{STEP}"
        t += STEP
      end
      # concat‑demuxer quirk: repeat last frame once
      f.puts "file '#{IMG_SILENT}'"
    end

    # ---------- 4. Create the video -------------------------------------------
    system "ffmpeg", "-y",
           "-f", "concat", "-safe", "0", "-i", FRAMES_TXT,
           "-vsync", "vfr",          # <‑‑ keep the VFR timestamps
           # "-r", (1.0 / STEP).to_i.to_s,  # declare 2 fps (optional but nice)
           "-i", AUDIO,
           "-c:v", "libx264", "-pix_fmt", "yuv420p",
           "-c:a", "aac",
           "-shortest",
           OUTFILE


    puts "✅  Wrote #{OUTFILE}"
  end
end
