class UpdateSlackAvatarJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      update_avatar_if_needed(user)
    end
  end

  private

  def update_avatar_if_needed(user)
    slack_id = user.slack_id
    current_avatar = user.avatar
    
    begin
      user_info = User.fetch_slack_user_info(slack_id)
      new_avatar = user_info.user.profile.image_original.presence || user_info.user.profile.image_512
      
      if new_avatar != current_avatar
        Rails.logger.tagged("AvatarUpdate") do
          Rails.logger.info({
            event: "updating_avatar",
            user_id: user.id,
            slack_id: slack_id,
            old_avatar: current_avatar,
            new_avatar: new_avatar
          }.to_json)
        end
        
        user.update!(avatar: new_avatar)
      end
    rescue StandardError => e
      Rails.logger.tagged("AvatarUpdate") do
        Rails.logger.error({
          event: "avatar_update_failed",
          user_id: user.id,
          slack_id: slack_id,
          error: e.message
        }.to_json)
      end
    end
  end
end 