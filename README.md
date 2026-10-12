# AthleteAce

AthleteAce runs on Ruby 4.0.7, Rails 8.1.4, and PostgreSQL. Ruby is pinned in
`.ruby-version` and `mise.toml`.

## Local development

Activate the pinned Ruby with mise, make sure PostgreSQL is running, then run:

```sh
bin/setup --skip-server
bin/dev
```

`bin/dev` starts Rails and the Tailwind CSS watcher.

## Optional manual checks

Tests and analysis tools remain available when useful; they do not run automatically:

```sh
RAILS_ENV=test bin/rails db:prepare tailwindcss:build
bundle exec rspec
bundle exec rubocop
bundle exec brakeman
bin/importmap audit
```

Browser tests also need Google Chrome. Build Tailwind before browser tests so
visibility and navigation checks use the application's CSS.

## CI deferred until launch

The GitHub Actions CI workflow is disabled, and its workflow file, `bin/ci`, and
`config/ci.rb` have been removed. Pull requests and pushes to `main` do not run the
former test/security pipeline. No CI checks are required for merging.

The separate Claude Code Review and Claude mention workflows remain enabled.
Dependabot also remains enabled for dependency update proposals.

Revisit automated tests and security scans during launch preparation. The previous
CI setup can be recovered from Git history; include Tailwind compilation before
browser tests when rebuilding it. This change does not configure deployment.
