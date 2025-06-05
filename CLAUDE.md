# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Database Operations
- `rails db:seed` - Seed database with sports data from JSON files in `db/seeds/athlete_ace_data/`
- `rails db:reset` - Drop, create, migrate, and seed database
- `rails db:migrate` - Run pending migrations

### Testing
- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/models/player_spec.rb` - Run specific test file
- `bundle exec rspec spec/features/quest_management_spec.rb` - Run feature tests

### Code Quality
- `bundle exec rubocop` - Run Ruby style linter
- `bundle exec brakeman` - Run security analysis

### Development Server
- `bin/dev` - Start development server with Procfile.dev (Rails + Tailwind CSS)
- `rails server` - Start Rails server only

## Architecture Overview

### Core Domain Models
AthleteAce is a sports data application with hierarchical relationships:
- **Sports** → **Leagues** → **Conferences** → **Divisions** → **Teams** → **Players**
- **Countries** → **States** → **Cities** → **Stadiums**
- **Memberships** track team participation in divisions over time
- **Ratings** system with configurable **Spectrums** for player evaluation
- **Quests/Achievements** gamification system

### Filterable System
The application's core feature is a sophisticated filtering system that allows navigation through related resources:

- **Filterable Concern** (`app/controllers/concerns/filterable.rb`): Provides filtering logic with intelligent join path resolution
- **FilterableAssociations** (`config/initializers/filterable_associations.rb`): Centralized configuration defining which models can filter others
- **Modular Routes** (`config/routes/filterable.rb`): DSL for generating filtered resource routes
- **Filter Helpers** (`app/helpers/filterable_*.rb`): UI components for filter panels and navigation

Key filterable URLs: `/teams/123/players`, `/leagues/456/teams/123/players`

### Data Seeding Architecture
- **JSON-driven**: All sports data lives in `db/seeds/athlete_ace_data/` as JSON files
- **Dual Format Support**: Both per-team files and league-wide files for player data
- **Versioned Seeding**: Tracks seed versions to prevent duplicate data
- **Helper Methods**: Centralized player creation logic in `db/seeds.rb`

### Authentication & Games
- **Devise** for user authentication (`Ace` model)
- **Strength Training**: Various game modes for learning athlete names
- **Division Guessing**: Interactive games with attempt tracking via `GameAttempt` model

## Code Conventions

### Ruby Style (.windsurfrules)
- Minimize parentheses in method calls when not needed for clarity
- Use Rails tag builders instead of raw HTML in ERB templates
- Create reusable helper methods for common template patterns
- Parametrize helper methods to work across multiple domain models

### CSS/Styling
- **Tailwind CSS** primary styling framework
- Group Tailwind classes into helper methods for reusability
- Use CSS classes with `@apply` directive for similar structures
- Three template types: admin scaffolds, user scaffolds, custom interfaces

### Helper Method Parameters
Choose appropriate parameter passing:
- `@variables` for controller instance variables
- Method parameters for explicit values
- Hash elements for optional configurations

### DOM IDs
Use descriptive suffixes: `dom_id(team, :quiz_link_for)` rather than `dom_id(team, :quiz_link)`

## Technology Stack
- **Rails 8.0.2** with Ruby 3.3.0
- **PostgreSQL** database with separate schemas for cable/cache/queue
- **Tailwind CSS 4.2** for styling
- **Turbo/Stimulus** for JavaScript interactions
- **RSpec** for testing with FactoryBot, Capybara, Shoulda Matchers
- **Pagy** for pagination
- **Ransack** for search functionality
- **Devise** for authentication