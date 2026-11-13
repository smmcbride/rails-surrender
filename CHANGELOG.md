# Changelog

## 0.2.0

### Breaking
- `surrenders` takes the fields to render by default as arguments, and the fields a request may add as `available:`.
  Surrender tells associations from attributes itself, so `attributes:`, `expands:`, `available_attributes:` and
  `available_expands:` are removed and raise `ArgumentError`. For example,
  `surrenders attributes: %i[id title], expands: [:author], available_attributes: [:pages]` becomes
  `surrenders :id, :title, :author, available: [:pages]`.
- Requires Rails 8.0 or 8.1 and Ruby 3.3 or newer. Rails 7 and Ruby 3.0–3.2 are no longer supported.
- `kaminari` and `oj` are no longer pinned to exact versions (`~> 1.2` and `~> 3.13`).
- The `<name>_to` and `<name>_from` filters on date and time columns are removed. They duplicated `_before` and
  `_after` but for a single instant, which mostly caused confusion. Use `_before` and `_after` with a time instead,
  such as `created_before:'2022-01-01T00:00:01Z'`.
- The `_before` and `_after` filters accept only ISO 8601 dates and times, such as `'2022-01-01'` or
  `'2022-01-01T13:30:00Z'`, and raise `Rails::Surrender::Error` for anything else. Previously a value that wasn't a
  time was compared as `NULL` and silently matched nothing.

### Fixed
- Apps that eager load (the production default) no longer fail at boot with `undefined method 'surrenders'`. Surrender
  now hooks into ActiveRecord and ActionController with load hooks instead of `after_initialize`.
- `filter_by_*` scopes are generated on first use instead of when a model is defined, so loading a model no longer
  queries the database, models whose table is created after boot still get them, and abstract classes not named
  `ApplicationRecord` are skipped. Errors while defining them are no longer silently swallowed.
  `filter_by_*` scopes the app defines, on the model or a superclass, always take precedence over generated ones.
- Rendering a collection whose model has STI subclasses no longer raises `NameError`.
- Rendering an STI record no longer loops forever, and STI subclasses are recognised as their base class when
  stopping circular expansion.
- `count` counts every matching resource instead of only the first page.
- `surrender nil` renders `{}`, and arrays are rendered as given, as intended.
- A `current_ability` defined as a private controller method is now used for authorization.
- A nested exclude such as `exclude=author:[name]` removes only the nested attributes, instead of the whole `author`.
- Associations excluded by the request or the controller, or read only by an excluded `*_ids` attribute, are no longer
  preloaded, saving a query for each one. A rendered `*_ids` attribute preloads only its association, not that
  association's own expands.
- A blank `sort` parameter is ignored instead of rejected, so API explorers that send empty fields still work.
- Quoted values in `filter`, `include` and `exclude` are kept as given. A space was inserted after every colon and
  comma, even inside quotes, so `'13:30'` arrived as `'13: 30'`.

### Changed
- Locale files are loaded through the Railtie.
- Removed the unused ActiveRecord patch files and test skeleton.
- Added a request-level test suite run against Rails 8.0 and 8.1.

## 0.1.0
- Initial release.
