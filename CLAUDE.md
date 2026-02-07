# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment & Setup

This is an Elixir/Phoenix application using Nix for development environment management. The setup requires:

1. **Prerequisites**: Nix with flakes enabled and Docker
2. **Initial setup**: `nix develop` then `docker-compose up -d` then `mix bb.init`
3. **Daily development**: Start with `nix-shell` and ensure postgres is running with `docker-compose up -d`

## Common Commands

### Development
- **Start server**: `scripts/server` (starts Phoenix server with IEx console)
- **Run all tests**: `scripts/test`
- **Run specific test**: `scripts/test path/to/test.exs:LINENUMBER`
- **Format code**: `scripts/format`
- **Update dependencies**: `mix setup`

### Mix Aliases
- **Initialize project**: `mix bb.init` (copies env, installs deps, runs setup)
- **Setup dependencies**: `mix setup` (gets deps, migrates DB, installs npm packages)
- **Database operations**: `mix ecto.setup`, `mix ecto.reset`
- **Deploy assets**: `mix assets.deploy`

### Testing
All tests require the test database to be set up. The `scripts/test` command handles database creation and migration automatically.

## Architecture Overview

### Core Domain Structure
The application follows Phoenix context patterns with these main domains:

- **BikeBrigade.Delivery**: Core delivery operations (campaigns, tasks, opportunities, programs)
- **BikeBrigade.Riders**: Rider management, tags, and statistics
- **BikeBrigade.Messaging**: SMS, Slack integration, message templates, and banners
- **BikeBrigade.Locations**: Geographic data, neighborhoods, and location management
- **BikeBrigade.Accounts**: User authentication and management

### Key Components

**External Integrations**:
- Google APIs (Drive, Sheets, Storage, Maps)
- Twilio for SMS
- Slack API
- Mailchimp integration

**Real-time Features**:
- Phoenix LiveView for interactive UI
- Phoenix PubSub for real-time updates
- Presence tracking for user status

**Data Layer**:
- PostgreSQL with PostGIS for geographic data
- Ecto for database operations
- Custom views for statistics and reporting

### Frontend Architecture
- **Phoenix LiveView**: Primary UI framework for real-time interactions
- **TailwindCSS**: Styling framework
- **Alpine.js**: JavaScript interactivity (v2.8.2)
- **LeafletJS**: Map functionality
- **Chart.js**: Data visualization

### File Organization
- `lib/bike_brigade/`: Core business logic contexts
- `lib/bike_brigade_web/`: Web interface (controllers, live views, components)
- `priv/repo/migrations/`: Database migrations
- `priv/repo/sql/`: Database views and functions
- `assets/`: Frontend assets (JS, CSS)
- `scripts/`: Development utility scripts

### Testing Strategy
- Context tests in `test/bike_brigade/`
- LiveView tests in `test/bike_brigade_web/live/`
- Controller tests in `test/bike_brigade_web/controllers/`
- Fixtures and support modules in `test/support/`

## Development Notes

### Code Style
- **ALWAYS run `scripts/format` before committing changes or presenting final code**

### Database
The application uses PostgreSQL with several extensions including PostGIS for geographic data, fuzzystrmatch for fuzzy matching, and unaccent for text processing.

### Deployment
- **Staging**: Force push to staging branch using `scripts/deploy_staging`
- **Production**: Automatic deployment on pushes to main branch

### Distributed Architecture
Uses Horde and libcluster for distributed Elixir deployments with automatic node discovery and process distribution.