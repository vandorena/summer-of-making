class AddMusicPlayedToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :music_played, :boolean
  end
end
