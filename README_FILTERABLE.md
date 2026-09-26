# AthleteAce Filterable System

Filtering lets you browse a resource through one related record, e.g. `/teams/12/players` or `/leagues/3/teams`.

- Configuration: `config/initializers/filterable_associations.rb`
- Routes: `config/routes/filterable.rb` and `config/routes/locations.rb`
- Controller concerns: `app/controllers/concerns/filterable.rb` and `filter_loader.rb`

See `docs/filterable.md` for how the pieces fit together and how to add a filter.
