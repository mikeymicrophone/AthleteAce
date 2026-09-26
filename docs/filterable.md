# Filterable Resources

## Overview

Filtering lets you browse a resource through one related record, e.g. `/teams/12/players` lists a team's players and `/teams/12/players/345` shows one of them with a breadcrumb back to the team. Each URL nests one level: a filtering record, then the resource.

## Configuration

`config/initializers/filterable_associations.rb` lists, for each resource, the models that can filter it:

```ruby
FilterableAssociations::ASSOCIATIONS = {
  players: [:sport, :league, :stadium, :team, :state, :city],
  teams: [:sport, :league, :conference, :division, :state, :city, :stadium],
  # ...
}
```

- `FilterableAssociations.for(controller_name)` returns the filters for a controller's resource.
- `FilterableAssociations.from(model_name)` returns the resources a model can filter.

Every model listed for a resource must define an association named after that resource (e.g. `Team#players`), because filtering calls it directly and `association_links` counts it for every row.

## Routes

`config/routes/locations.rb` calls `filterable_resources` (defined in `config/routes/filterable.rb`) for every configured resource. It generates index and show routes under each filtering model:

```
/teams/:team_id/players
/teams/:team_id/players/:id
```

## Controllers

```ruby
class PlayersController < ApplicationController
  include Filterable
  include FilterLoader

  def index
    load_current_filters             # sets @current_filters and e.g. @team
    base_query = apply_filter :players
    load_filter_options
  end

  def show
    load_current_filters
    @filtered_breadcrumb = build_filtered_breadcrumb @player, @current_filters
  end
end
```

- `apply_filter :players` finds the filter param in the URL (e.g. `team_id`), sets `@team`, and returns `@team.players`. With no filter it returns `Player.all`.
- `load_current_filters` loads each filter record from params into `@current_filters`.
- `build_filtered_breadcrumb` builds breadcrumb items that link to each filter's own page, ending with the current resource.

## Views

- `association_links(record)` (in `TeamsHelper`) renders a count and link for each resource the record can filter, e.g. "12 teams" linking to `/leagues/3/teams`.
- `filtered_show_header` (in `FilteredShowHelper`) renders the breadcrumb and title on filtered show pages.

## Adding a filter

1. Add the filtering model to the resource's list in `ASSOCIATIONS`.
2. Make sure the filtering model has an association named after the resource, and that every model already listed for that resource still does.
3. The routes are generated automatically; the resource's controller needs `include Filterable` and `apply_filter`.
