# Filterable Functionality Documentation

## Overview

The filterable functionality in AthleteAce allows for dynamic filtering of resources based on their relationships. This enables users to navigate through connected resources (e.g., viewing players filtered by a specific team, league, or division) with consistent URL patterns and UI components.

## Key Components

### 1. Filterable Concern

Located in `app/controllers/concerns/filterable.rb`, this module provides the core filtering functionality:

- `apply_filter`: Sets instance variables and returns filtered collections
- `apply_filters`: Applies multiple filters to a relation with optimized joins
- `build_filtered_query`: Intelligently builds queries with multiple filters
- `filtered_path`: Helper to build filtered paths for links

### 2. FilterLoader Concern

Located in `app/controllers/concerns/filter_loader.rb`, this module helps controllers:

- Load current filters from params
- Set appropriate instance variables
- Prepare filter options for UI components

### 3. Centralized Configuration

Filterable associations are defined in `config/initializers/filterable_associations.rb`:

```ruby
# Example configuration
FilterableAssociations.config = {
  player: [:team, :league, :sport, :division, :conference, :country, :state, :city],
  team: [:league, :division, :conference, :sport, :country, :state, :city]
}

# Complex join paths
FilterableAssociations.join_paths = {
  player: {
    division: [:team, :division],
    conference: [:team, :division, :conference]
  }
}
```

### 4. Filterable Routes

Defined in `config/routes/filterable.rb` and used in modular route files:

- `filterable_resources`: A DSL method that generates filtered routes
- Supports nested resources with appropriate shallow nesting
- Used in all resource route files (players.rb, teams.rb, etc.)

### 5. View Helpers

Located in:
- `app/helpers/filterable_helper.rb`: Core filtering UI components
- `app/helpers/filterable_navigation_helper.rb`: Navigation components

These provide methods for:
- Rendering filterable links
- Creating breadcrumbs
- Building filter panels
- Generating filter chips
- Producing context-aware navigation

## Implementation

### Controller Setup

1. Include the concerns in your controller:

```ruby
class PlayersController < ApplicationController
  include Filterable
  include FilterLoader
  
  # Rest of controller code
end
```

2. Use the filter loader in your actions:

```ruby
def index
  @players = apply_filters(Player.all)
  load_filter_options  # Prepares options for filter selectors
  load_current_filters # Sets @current_filters
end
```

### Routes Setup

1. Use the `filterable_resources` method in your route files:

```ruby
# config/routes/players.rb
Rails.application.routes.draw do
  filterable_resources :players do
    resources :ratings, only: [:new, :create]
  end
end
```

### View Implementation

1. Include the filter panel in your index view:

```erb
<%# app/views/players/index.html.erb %>
<%= render 'filter_ui' %>
```

2. Create a filter UI partial:

```erb
<%# app/views/players/_filter_ui.html.erb %>
<%= render 'shared/filter_panel', 
           resource: :players,
           current_filters: @current_filters,
           filter_options: @filter_options %>
```

## Filter Navigation

The filter navigation system provides two main components:

1. Primary navigation bar: Shows main resource types
2. Context navigation: Shows related resources based on current filters

Example usage:

```erb
<%= filterable_navigation :players, @current_filters %>
<%= filterable_context_nav :players, @current_filters %>
```

## URL Patterns

Filterable URLs follow these patterns:

- Standard index: `/players`
- Single filter: `/teams/123/players`
- Multiple filters: `/leagues/456/teams/123/players`
- Filtered show: `/teams/123/players/789`

## Best Practices

1. **Centralize Configuration**: Add new filterable associations to the configuration file, not in controllers
2. **Use Helper Methods**: Leverage the helper methods for consistent UI
3. **Join Paths**: Define complex join paths for indirect associations
4. **Reuse Components**: Use the shared partials for consistent UI
5. **Resource Hierarchy**: Respect the resource hierarchy in URL construction
