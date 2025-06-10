class SignpostController < ApplicationController
  before_action :authenticate_user!, only: [ :index ]

  def index
    @user = current_user

    if params[:reset].present? && @user&.tutorial_progress
      @user.tutorial_progress.reset_step!(params[:reset])

      tutorial = get_tutorials.find { |t| t[:id] == params[:reset] }
      tutorial_path = tutorial&.[](:path) || signpost_path
      redirect_to tutorial_path, notice: "Tutorial reset! You can now replay the #{params[:reset].humanize} tutorial."
    end

    @account_status = build_account_status
    @announcements = get_announcements
    @tutorials = get_tutorials
  end

  def show
  end

  private

  def build_account_status
    return {} unless @user

    {
      hackatime_linked: @user.has_hackatime?,
      id_verified: @user.ysws_verified?,
      identity_vault_linked: @user.identity_vault_id.present?
    }
  end

  def get_announcements
    announcements = []

    announcements << {
      id: 1,
      title: "Welcome to Summer of Making!",
      content: "Complete the tutorials yada yada yada. I just created this section, but might put it at top because I remember signpost in HS had smth similar. Anyways, we have a space to post announcements and stuff. I'm not sure if we'll use it, but it's here. Need to implement dismiss",
      type: "info",
      created_at: Time.now
    }

    announcements
  end

  def get_tutorials
    tutorials = [
      {
        id: "signpost",
        title: "This is the signpost!",
        description: "This is where you'll see announcements, tutorials, account status and anything that needs your attention. Think of it as your notification/action center!",
        path: "/signpost",
        completed: tutorial_completed?("signpost")
      },
      {
        id: "explore",
        title: "Explore Projects",
        description: "This is like a social feed where you'll see devlogs – mini blogs from other hackers sharing what they're working on. Follow other hackers to see their projects! Check the Following tab for projects you've hit follow on, and browse the Gallery for all the cool stuff hackers have built.",
        path: "/explore",
        completed: tutorial_completed?("explore")
      },
      {
        id: "my_projects",
        title: "Visit My Projects",
        description: "This is where you can see all your projects, create new ones, and edit or delete them. Go crazy!",
        path: "/my_projects",
        completed: tutorial_completed?("my_projects")
      },
      {
        id: "vote",
        title: "Check out the Arena",
        description: "This is where you'll vote on other hackers' projects and where your own projects will get voted on too. The better your projects perform, the more shells you'll earn. Go ahead – pick left, right, or maybe call it a tie?",
        path: "/votes/new",
        completed: tutorial_completed?("vote")
      },
      {
        id: "shop",
        title: "Visit the Shop",
        description: "This is where you can buy stuff with your shells. You'll earn shells by working on your projects and shipping them! PS: Take a look at the shop items – they're all made by hackers for hackers. (go ahead, get greedy!)",
        path: "/shop",
        completed: tutorial_completed?("shop")
      }
    ]

    # Sort tutorials so incomplete ones appear first
    tutorials.sort_by { |t| [ t[:completed] ? 1 : 0, t[:id] ] }
  end

  def tutorial_completed?(step_name)
    return false unless @user&.tutorial_progress

    @user.tutorial_progress.step_completed?(step_name)
  end
end
