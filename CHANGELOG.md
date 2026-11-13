# Changelog

## 0.2.0

### Breaking
- Requires Rails 8.0 or 8.1 and Ruby 3.3 or newer. Rails 7 and Ruby 3.0–3.2 are no longer supported.
- `kaminari` and `oj` are no longer pinned to exact versions (`~> 1.2` and `~> 3.13`).

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

### Changed
- Locale files are loaded through the Railtie.
- Removed the unused ActiveRecord patch files and test skeleton.
- Added a request-level test suite run against Rails 8.0 and 8.1.

## 0.1.0
- Initial release.
