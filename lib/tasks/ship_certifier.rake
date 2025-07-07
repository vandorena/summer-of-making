namespace :ship_certifier do
  desc "give rights"
  task :grant, [ :email ] => :environment do |task, args|
    email = args[:email]

    if email.blank?
      puts "you need a email ya goober rails ship_certifier:grant[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email.downcase.strip)

    if user.nil?
      puts "#{email} not found"
      exit 1
    end

    if user.ship_certifier?
      puts "#{email}' already has that"
      exit 0
    end

    user.add_permission("shipcert")
    puts "gave rights to #{email}"
  end

  desc "revoke rights"
  task :revoke, [ :email ] => :environment do |task, args|
    email = args[:email]

    if email.blank?
      puts "you need a email ya goober rails ship_certifier:revoke[user@example.com]"
      exit 1
    end

    user = User.find_by(email: email.downcase.strip)

    if user.nil?
      puts "#{email} not found"
      exit 1
    end

    unless user.ship_certifier?
      puts "#{email}' does not have that"
      exit 0
    end

    user.remove_permission("shipcert")
    puts "revoked rights from #{email}"
  end

  desc "list all ship certifiers"
  task list: :environment do
    ship_certifiers = User.where("permissions LIKE ?", "%shipcert%")
                         .pluck(:email, :display_name)

    if ship_certifiers.empty?
      puts "theres nothing here cuzo"
    else
      puts "found em!"
      ship_certifiers.each do |email, name|
        puts "  - #{name} (#{email})"
      end
    end
  end
end
