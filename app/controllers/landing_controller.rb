class LandingController < ApplicationController
  def index
    redirect_to explore_path if user_signed_in?
    @prizes = [
      {
        name: "Flipper Zero",
        cost: 120,
        image: nil
      },
      {
        name: "Framework Laptop DIY Edition",
        cost: 800,
        image: nil
      },
      {
        name: "Pinecil Soldering Iron",
        cost: 30,
        image: nil
      },
      {
        name: "Cloud Credits - Cloudflare",
        cost: 50,
        image: nil
      },
      {
        name: "PCB Credits - JLCPCB",
        cost: 30,
        image: nil
      },
      {
        name: "iPad with Apple Pencil",
        cost: 450,
        image: nil
      },
      {
        name: "Raspberry Pi 5 Starter Kit",
        cost: 90,
        image: nil
      },
      {
        name: "BLÅHAJ Soft Toy",
        cost: 20,
        image: nil
      },
      {
        name: "Sony WH-1000XM4 Headphones",
        cost: 250,
        image: nil
      },
      {
        name: "Steam Game - Factorio",
        cost: 25,
        image: nil
      },
      {
        name: "Ben Eater 8-bit Computer Kit",
        cost: 200,
        image: nil
      },
      {
        name: "MORE FUDGE!",
        cost: 35,
        image: nil
      }
    ]
  end
end
