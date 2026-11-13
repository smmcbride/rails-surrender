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
- The `reload:` option of `surrender` is removed, and passing it raises `ArgumentError`. It only existed to fetch a
  record again so its associations could be preloaded; Surrender now preloads the record it is given. An association
  the controller already loaded or changed in memory therefore renders as it is in memory, not as stored.
- Fields render in a fixed order: `id` first, then other attributes, then `*_ids` id lists, then expands. Within each
  group, default fields come first, then those the controller includes, then those the request includes.
- An STI record inside a collection renders its own class's fields, as it does when rendered alone. A `Novel` in
  `Book.all` used to render only `Book`'s fields.
- A polymorphic association listed as a field raises `ArgumentError` when the response is built. It already failed,
  with `Polymorphic associations do not support computing the class`; support is tracked in
  [#6](https://github.com/smmcbride/rails-surrender/issues/6).
- A name the controller includes that is not an association or `*_ids` id list renders as an attribute, so a name the
  model can't answer raises `NoMethodError` instead of being silently skipped.
- The `ids` query param is removed, and a request that sends it renders the resources as usual. To list only ids,
  exclude the other default fields, such as `exclude=title,genre,author`.
- A `sort_by_<name>` scope the model defines wins over a column of the same name, as `filter_by_` scopes the model
  defines already win over generated ones. Previously the column sort was used and the scope never ran.
- `Rails::Surrender::FieldTree.new` takes the request's `include:` and `exclude:` as query strings, such as
  `include: 'books:[pages]'`, rather than parsed lists.
- `Rails::Surrender::QueryParamParser` is removed. Its page defaults are `Rails::Surrender::Selection::PAGE_DEFAULT`
  and `PER_PAGE_DEFAULT`. `Rails::Surrender::ModelFilterScopes` is now `Rails::Surrender::Selection::Filtering`.

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
- Preloading always matches what renders. Collections of STI models no longer preload subclass associations they
  never render ([#2](https://github.com/smmcbride/rails-surrender/issues/2)), and associations only a subclass renders are
  preloaded instead of loaded once per record.
- A request include that is not available, at any depth, is rejected before any query runs.
- A `belongs_to` with no record renders `null` whatever the ability allows.
- A single resource no longer gets an `X-Sort` header, as it isn't sorted.
- Paginated requests run one query fewer: `page_total` in `X-Pagination` follows from the total instead of a second
  count.
- A filter term with no value, such as `filter=genre`, is rejected as improperly formatted. It was reported as an
  unknown filter named after its first letter: `g is not a valid filter parameter.`

### Changed
- A selection applies a request's filter, sort and page to a relation, and models resolve filter and sort names with
  `surrender_filter` and `surrender_sort`. `FilterBuilder`, `SortBuilder`, `PaginationBuilder` and `Render::Ids` and
  `Render::Count` are removed.
- Surrender works out the fields a request renders once, as a field tree, and both preloading and rendering read it.
  `Render::Configuration` and the classes under `Render::Resource` are replaced by `Rails::Surrender::FieldTree`.
- Locale files are loaded through the Railtie.
- Removed the unused ActiveRecord patch files and test skeleton.
- Added a request-level test suite run against Rails 8.0 and 8.1.

## 0.1.0
- Initial release.
