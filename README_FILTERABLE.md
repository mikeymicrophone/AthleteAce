# AthleteAce Filterable System

The filterable system allows for dynamic, relationship-based filtering of resources throughout the application. This document provides a quick overview of how to use and extend this functionality.

## Key Features

- **Nested Route Filtering:** Access resources through their relationships (e.g., `/teams/1/players`)
- **Multiple Filter Support:** Apply multiple filters simultaneously (e.g., `/leagues/1/teams/2/players`)
- **Centralized Configuration:** All filterable associations defined in one place
- **Reusable UI Components:** Standard filter panels, breadcrumbs, and navigation elements
- **Show Page Filtering:** Contextual navigation from filtered index to show pages

## Implementation Overview

### Controllers

To make a controller filterable:

```ruby
class PlayersController < ApplicationController
  include Filterable
  include FilterLoader
  
  def index
    @players = apply_filters(Player.all)
    load_current_filters
    load_filter_options
    # Rest of controller code
  end
  
  def show
    load_current_filters
    @filtered_breadcrumb = build_filtered_breadcrumb(@player, @current_filters)
    # Rest of controller code
  end
end
```

### Views

Add filter UI to index views:

```erb
<%# app/views/players/index.html.erb %>
<%= render 'filter_ui' %>
```

Add filter navigation to show views:

```erb
<%# app/views/players/show.html.erb %>
<%= render 'filtered_show' if @filtered_breadcrumb.present? %>
```

### Configuration

Filterable associations are configured in `config/initializers/filterable_associations.rb`:

```ruby
FilterableAssociations.config = {
  player: [:team, :league, :sport, :division, :conference, :country, :state, :city],
  team: [:league, :division, :conference, :sport, :country, :state, :city],
  # other resource configurations...
}
```

## Routes

Modular route files in `config/routes/` use the `filterable_resources` method to define filterable routes:

```ruby
# config/routes/players.rb
Rails.application.routes.draw do
  filterable_resources :players do
    resources :ratings, only: [:new, :create]
  end
end
```

## Example Filtering Scenarios

1. **Basic filtering:** `/teams/1/players` - All players on team with ID 1
2. **Multi-level filtering:** `/leagues/2/teams/1/players` - All players on team 1 in league 2
3. **Show page with context:** `/teams/1/players/3` - Player 3 in the context of team 1

## UI Components

The filterable system includes these reusable UI components:

- **Filter Panel:** Dropdown selectors for applying filters
- **Filter Breadcrumbs:** Visual trail of applied filters with clear options
- **Resource Navigation:** Context-aware links to related resources
- **Filter Chips:** Compact display of active filters with removal option

## Adding a New Filterable Resource

1. Add the resource to the configuration in `filterable_associations.rb`
2. Create a routes file in `config/routes/` using `filterable_resources`
3. Include the concerns in the controller
4. Add the filter UI partials to the views

## Detailed Documentation

For more detailed information, see the comprehensive documentation in `docs/filterable.md`.

## Example of Usage with Tailwind CSS

The UI components make extensive use of Tailwind CSS for consistent styling. The filter panels and breadcrumbs have been designed with accessibility and responsive layout in mind.

We've used concise, meaningful class combinations that can be easily converted to helper methods for reuse throughout the application.
