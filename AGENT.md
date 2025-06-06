# AGENT.md - Rails SOM Project

## Important: Always run formatting and linting after every code change
- Run `docker compose run web bundle exec rubocop -A` after any code modifications

## Commands (via Docker Compose)
- **Tests**: `rails test` (all), `docker compose run web rails test test/models/user_test.rb` (single file), `docker compose run web rails test test/models/user_test.rb -n test_method_name` (single test) - Note: Limited test coverage
- **Lint**: `docker compose run web bundle exec rubocop` (check), `docker compose run web bundle exec rubocop -A` (auto-fix)
- **Console**: `docker compose run web rails c` (interactive console)
- **Server**: `docker compose run --service-ports web rails s -b 0.0.0.0` (development server)
- **Database**: `docker compose run web rails db:migrate`, `docker compose run web rails db:create`, `docker compose run web rails db:schema:load`, `docker compose run web rails db:seed`
- **Security**: `docker compose run web bundle exec brakeman` (security audit)
- **JS Security**: `docker compose run web bin/importmap audit` (JS dependency scan)
- **Zeitwerk**: `docker compose run web bin/rails zeitwerk:check` (autoloader check)