# Hierarchical Sort Configuration

# Tables that support hierarchical sorting, keyed by sort context.
# HierarchicalSortService only sorts by columns of these models (plus its explicit mappings).
HIERARCHICAL_SORT_MODELS = {
  players: 'Player',
  leagues: 'League',
  divisions: 'Division'
}.freeze
