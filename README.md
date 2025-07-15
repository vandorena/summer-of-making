# Summer of Making

## Build stuff. Get stuff. Repeat.

> The Summer of Making starts now! The premises is simple, build stuff, get stuff! Your job is to build personal coding projects, websites, games, apps, whatever you want! Tell the story of your project with updates on your devlog. One you're done, your project goes to head-to-head match ups voted on by the community. The more votes you get, the more shells you earn! You can spend shells on rewards in the shop. We're giving away MacBooks, 3D Printers, Flipper Zeros, everything you need to keep building. Build stuff, get Stuff, repeat until the summer ends on August 31st. This summer is yours for the making, get started summer.hackclub.com. For teenagers 18 or under.

## Run this thing

1. Clone and copy over your `.env` file from the example (we might have forgotten to update it so uhhh whoops)
2. For the Slack bot, make sure you have the following scopes enabled: `channels:history`, `chat:write`, `groups:history`, `im:write`, `reactions:write`, `users.profile:read`, `users:read`, `users:read.email`, `im:history`, `im:read`.
3. Make sure you have PostgreSQL running locally. You can use Docker to make this easier:

   ```bash
   docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -p 5432:5432 -d postgres
   ```

   Then edit this line in your `.env` file:

   ```env
   DATABASE_URL=postgres://postgres:mysecretpassword@localhost:5432/postgres
   ```

4. Run `bin/rails db:prepare` to prepare/seed the database.
5. You probably don't have access to IDV, so add `BYPASS_IDV=true` to your `.env` file. which will skip the IDV check.
6. Run `bin/dev` to start the development server on port 3000, then visit `http://localhost:3000` in your browser.
7. Profit?

Or just be based and run the Docker files if your built like that.

## Contributions

Why would you do this to yourself... but if you really want to, fork this and make a pull request. If your stuff is cool, we will merge it and give you a firm handshake or something.
