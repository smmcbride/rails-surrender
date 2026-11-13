# Surrender
A JSON rendering platform for Rails APIs. Provides many controls through URL query parameters for clients to craft 
API responses from your resources.

## Requirements
* Ruby 3.3 or newer
* Rails 8.0 or 8.1

The gem's version names the Rails version it supports. Use 8.x for Rails 8.0 and 8.1, and 7.0.0 (on the
`7-0-stable` branch) for Rails 7.0.

Rails 8.0 is not compatible with version 3 of the `json` gem, so Rails 8.0 apps should keep `json` below 3:

```ruby
gem 'json', '< 3'
```

## Features
Surrender adds a number of helpful features to API requests, through URL query parameters to craft the structure of the
response:

### Sorting
Most attributes on the requested resource can be targeted for sorting.  Sorting is provided for to the API with the 
'sort' query parameter.

| example query param | description                                               |
|---------------------|-----------------------------------------------------------|
| `sort=name`         | Sort the results by the `name` attribute                  |
| `sort=-created_at`  | Sort the results in reverse by the `created_at` attribute |
| `sort=author.name`  | Sort the results by the `name` of each result's `author`  |

Sorting by a column of an association works for associations that hold one record, such as `belongs_to` and `has_one`.
An association that holds many would repeat each result once per associated record, so it is rejected.

A model can define its own sorts as scopes named `sort_by_<name>`, which take the direction, `'ASC'` or `'DESC'`. A
sort the model defines wins over a column of the same name, so `sort_by_title` can sort titles without regard to case:

```ruby
scope :sort_by_title, ->(direction) { order(Arel.sql("LOWER(title) #{direction}")) }
```


### Pagination
Pagination is provided internally using the 'kaminari' gem. Access is provided to the API with the  `page` and `per` 
query parameters

| example query param | description                        |
|---------------------|------------------------------------|
| `per=20`            | Request 20 results per page        |
| `page=2`            | Request the second page of results |

A page holds 50 resources unless the request sets `per`, and never more than 100, whatever `per` asks for. Both numbers
can be changed in the app's configuration (see Setup). `page` and `per` take positive whole numbers; anything else is
rejected with a `Rails::Surrender::Error`.

Paginated results will populate an `X-Pagination` header in the result set that provides a hash of the paginated
details. The hash is structured like:

```json
{
	"total": 70,
	"page_total": 3,
	"page": 2,
	"previous_page": 1,
	"next_page": 3,
	"last_page": 3,
	"per_page": 25,
	"offset": 25
}
```

### Filtering
`rails-surrender` adds a number of scopes to your models for filtering, and provides access to the filters with the 
`filter` query parameter. Most columns are provided with an equality filter and can be filtered on matching values. 
Date and Time columns are also provided with `_before` and `_after` filters, named after the column without its `_at`
suffix, which select records strictly before or after the given date or time. Examples are provided below:

Note: Time-based filters take an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date or time, such as
`'2022-01-01'`, `'2022-01-01T13:30:00Z'` or `'2022-01-01T13:30:00-05:00'`, surrounded by single or double quotes. A time
without an offset is in the app's time zone. Any other value is rejected with a `Rails::Surrender::Error`.

| example query param                           | description                                                                       |
|-----------------------------------------------|-----------------------------------------------------------------------------------|
| `filter=active:false`                         | filter for resources with the `active` attribute set to false                     |
| `filter=state:TX`                             | filter for resources with the `state` attribute of `TX`                           |
| `filter=created_before:'2022-01-01'`          | filter for resources with a `created_at` value _before_ Jan 01, 2022              |
| `filter=created_after:'2022-01-01'`           | filter for resources with a `created_at` value _after_ Jan 01, 2022               |
| `filter=created_after:'2022-01-01T13:30:00Z'` | filter for resources with a `created_at` value _after_ 1:30pm UTC on Jan 01, 2022 |


### Counting
Instead of rendering a full list of resources, `rails-surrender` can return only the _count_ of the number of resources
that _would_ be returned. A count ignores pagination: it counts every resource the filters select, not just one page.  This can be useful when combined with filters for basic reporting. Access is provided with
the `count` query parameter.

| example query param                                             | description                                          |
|-----------------------------------------------------------------|------------------------------------------------------|
| `count`                                                         | count the number of resources                        |
| `filter=state:TX&count`                                         | count the number of resources in the `state` of 'TX' |
| `filter=state:TX&count`                                         | count the number of resources in the `state` of 'TX' |
| `filter=created_before:'2022-01-01'&count`                      | count the number of resources created before 2022    |


### Including
the `include` (and `exclude` described below) directive provides an easy but powerful mechanism for crafting the shape 
of the response. For models that provide additional attributes or associations that are not rendered by default (see 
setup below) the `include` query parameter can be used to request those attributes and associations be rendered in the
request. The `include` parameter can request multiple attributes and associations, and for associations can include 
additional values on nested resources. Examples below:

| example query param                                                       | description                                                             |
|---------------------------------------------------------------------------|-------------------------------------------------------------------------|
| `include=created_at, updated_at`                                          | include the `created_at` and `updated at` attributes of the resource(s) |
| `include=work_orders`                                                     | include the `work_orders` association of the resource(s)                |
| `include=work_orders:[activities]`                                        | include the `work_orders` and it's `activities` association             |
| `include=created_at, work_orders:[created_at, activities:[created_at ]]`  | combine various attributes and associations and nested results          |

Each resource renders its `id` first, then its other attributes, then its `*_ids` lists, then its associations. Within
each group, the model's default fields come first, then those the controller includes, then those the request includes.


### Excluding
Exclude (and exclude below) provide an easy but powerful mechanism for crafting the shape of the response. Excluding 
works like the reverse of include. Models may define attributes or associations that are rendered by default, but
exclude can be used to prevent rendering of those attributes. Examples below:

| example query param              | description                                                                                          |
|----------------------------------|------------------------------------------------------------------------------------------------------|
| `exclude=created_at, updated_at` | exclude the `created_at` and `updated at` attributes of the resource(s) that are rendered by default |
| `exclude=work_orders`            | include the `work_orders` association of the resource(s) that is rendered by default                 |
| `exclude=activities:[creator]`   | keep the default `activities` association, but leave out each activity's `creator`                   |

To list only the ids of the resources, exclude every other field they render by default, such as
`exclude=title,genre,author`.


## Example Project
A full working example project is provided in the [rails-surrender-demo](https://github.com/smmcbride/rails-surrender-demo)
repository. It provides several models and endpoints demonstrating a working configuration of `rails-surrender`. The
project provides seed data, a browser explorer where each query parameter is a checkbox and the response is shown as
you send it, and a `bin/http` command for trying each query parameter from the terminal.


## Installation

This project is intended to be used in a Ruby on Rails project. To install, simply add this your Gemfile:

```ruby
gem 'rails-surrender', '~> 8.0'
```

and bundle:

```sh
% bundle
```

## Setup
Surrender setup begins in your models. To enable rendering of a model with this gem, call `surrenders` on it with the
fields to render by default, and optionally `available:` with the fields API clients can add with the `include` query
parameter. A field can be any model attribute or method, a `*_ids` attribute such as `chapter_ids`, or an association
such as one defined with `has_many` or `belongs_to`. Surrender renders associations as nested resources, using the
associated model's own `surrenders` fields, and renders every other field as an attribute.

An example invocation of the `surrenders` method is provided below:
```ruby
  surrenders :id, :title, :description, :status, :activities,
             available: [:created_at, :updated_at, :user]
```

A model that doesn't call `surrenders` renders its `id` and `created_at`. A subclass that calls `surrenders` adds its
fields to those of its superclass, and its records render them wherever they appear, including in a collection of the
superclass.

Surrender can't expand a polymorphic `belongs_to`, because it works out the fields to render before any record loads,
when the association has no class yet. Listing one as a field raises `ArgumentError`.

To invoke surrender in your controllers, simply end your controller action with a call to `surrender` with the 
resource you wish to render. An example controller action is provided below:

```ruby
  def index
    books = Book.all
    surrender books
  end
```


### Configuration

Surrender's page sizes are set in `config/application.rb`, or per environment in `config/environments/*.rb`:

```ruby
config.surrender.default_per_page = 50   # the page size when a request doesn't set `per`
config.surrender.max_per_page = 100      # the most a page holds, whatever `per` asks for; nil removes the limit
```

The app won't boot if the default is larger than the limit, or either isn't a positive whole number. Kaminari's own
page size settings don't apply to surrender's pages.

### Describing what a request may ask

`surrender_menu` lists everything a request may ask of a model, read from the same rules that check requests, for
documentation or an API explorer like the demo's:

```ruby
menu = Book.surrender_menu
menu.fields   # each with its name, kind (:attribute, :id_list or :expand), default?, and an expand's own menu
menu.filters  # each with its name and the column it compares, or nil for a filter the model defines
menu.sorts    # ['id', 'title', ..., 'author.name', 'title_length']
menu.page_size.default, menu.page_size.max   # 50 and 100 unless configured
```

### Additional Notes

Surrender prevents circular renderings. If a `Book` model, for example, expands its `Author`, and `Author` expands its
`books`, then surrender leaves out the `books` of an author rendered inside a book. It never expands an association
into a model already rendered above it, and it treats an STI subclass as its base class when checking.

Surrender prevents un-authorized access to associated resources by invoking the `current_ability` rule-set from the 
CanCanCan gem, if it is used in your Rails project. Any controller method named `current_ability`, public or private, 
that returns an object responding to `can?(:read, record)` is used the same way. If neither is present it will allow 
full access to associated resources.

## Development

The test suite boots a small Rails app (`spec/dummy`) against an in-memory SQLite database. Run it against the
latest Rails with:

```sh
bundle install
bundle exec rake
```

`rake` runs both the specs and RuboCop. To run the specs against each supported Rails version:

```sh
bundle exec appraisal install
bundle exec appraisal rspec
```
