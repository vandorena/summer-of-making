class SignpostController < ApplicationController
  before_action :authenticate_user!, only: [ :index ]

  def index
    @user = current_user
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

    if @user&.tutorial_progress && !@user.tutorial_progress.completed?
      announcements << {
        id: 1,
        title: "Welcome to Summer of Making!",
        content: "Complete the tutorials yada yada yada. I just created this section, but might put it at top because I remember signpost in HS had smth similar. Anyways, we have a space to post announcements and stuff. I'm not sure if we'll use it, but it's here. Need to implement dismiss",
        type: "info",
        created_at: Time.now
      }
    end

    announcements
  end

  def get_tutorials
    tutorials = [
      {
        id: "signpost",
        title: "This is the signpost!",
        description: "This is where you can see all the announcements and stuff. It's also where you can see your progress and complete the tutorials and post tutorials this'll serve as your dashboard. (and you can restart tutorials anytime you want)",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
        path: "/signpost",
        completed: tutorial_completed?("signpost")
      },
      {
        id: "explore",
        title: "Explore Projects",
        description: "Discover amazing projects from the community",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
        path: "/explore",
        completed: tutorial_completed?("explore")
      },
      {
        id: "gallery",
        title: "Browse Gallery",
        description: "Check out the project gallery and get inspired",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
        path: "/gallery",
        completed: tutorial_completed?("gallery")
      },
      {
        id: "my_projects",
        title: "Create Your Projects",
        description: "Set up your own projects and start building",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
        path: "/projects",
        completed: tutorial_completed?("my_projects")
      },
      {
        id: "vote",
        title: "Vote on Projects",
        description: "Participate in the community by voting on projects",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
        path: "/vote",
        completed: tutorial_completed?("vote")
      },
      {
        id: "shop",
        title: "Visit the Shop",
        description: "Explore available rewards and merchandise",
        difficulty: "beginner",
        estimated_time: "like 1 sec dude",
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
