# Surrender
A JSON rendering platform for Rails APIs. Provides many controls through URL query parameters for clients to craft 
API responses from your resources.

## Requirements
* Ruby 3.0, 3.1
* Rails 7.0, 7.1

Older versions may work fine but have yet to be tested.

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


### Pagination
Pagination is provided internally using the 'kaminari' gem. Access is provided to the API with the  `page` and `per` 
query parameters

| example query param | description                        |
|---------------------|------------------------------------|
| `per=20`            | Request 20 results per page        |
| `page=2`            | Request the second page of results |

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
Date and Time columns are provided with multiple filters to select dates/times before or after the given time.
Examples are provided below:

Note: Time-based filters must be surrounded by either single or double-quotes

| example query param                  | description                                                                  |
|--------------------------------------|------------------------------------------------------------------------------|
| `filter=active:false`                | filter for resources with the `active` attribute set to false                |
| `filter=state:TX`                    | filter for resources with the `state` attribute of `TX`                      |
| `filter=created_before:'2022-01-01'` | filter for resources with a `created_at` value _before_ Jan 01, 2022         |
| `filter=created_after:'2022-01-01'`  | filter for resources with a `created_at` value _after_ Jan 01, 2022          |
| `filter=created_to:'2022-01-01'`     | filter for resources with a `created_at` value _on_ of _before_ Jan 01, 2022 |
| `filter=created_from:'2022-01-01'`   | filter for resources with a `created_at` value _on_ or _after Jan 01, 2022   |


### Counting
Instead of rendering a full list of resources, `rails-surrender` can return only the _count_ of the number of resources
that _would_ be returned.  This can be useful when combined with filters for basic reporting. Access is provided with
the `count` query parameter.

| example query param                                             | description                                          |
|-----------------------------------------------------------------|------------------------------------------------------|
| `count`                                                         | count the number of resources                        |
| `filter=state:TX&count`                                         | count the number of resources in the `state` of 'TX' |
| `filter=state:TX&count`                                         | count the number of resources in the `state` of 'TX' |
| `filter=created_from:'2021-01-01,created_to:'2021-12-31'&count` | count the number of resources created in 2021        |


### Id Lists
Similar to counting, instead of rendering a full list of resources, `rails-surrender` can return only the _ids of the 
resources that _would_ be returned.  This can be useful when combined with filters for basic reporting. Access is 
provided with the `ids` query parameter.

| example query param                                           | description                                           |
|---------------------------------------------------------------|-------------------------------------------------------|
| `ids`                                                         | ids of the number of resources                        |
| `filter=state:TX&ids`                                         | ids of the number of resources in the `state` of 'TX' |
| `filter=state:TX&ids`                                         | ids of the number of resources in the `state` of 'TX' |
| `filter=created_from:'2021-01-01,created_to:'2021-12-31'&ids` | ids of the number of resources created in 2021        |


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


### Excluding
Exclude (and exclude below) provide an easy but powerful mechanism for crafting the shape of the response. Excluding 
works like the reverse of include. Models may define attributes or associations that are rendered by default, but
exclude can be used to prevent rendering of those attributes. Examples below:

| example query param              | description                                                                                          |
|----------------------------------|------------------------------------------------------------------------------------------------------|
| `exclude=created_at, updated_at` | exclude the `created_at` and `updated at` attributes of the resource(s) that are rendered by default |
| `exclude=work_orders`            | include the `work_orders` association of the resource(s) that is rendered by default                 |


## Example Project
A full working example project is provided in the [rails-surrender-demo](https://github.com/smmcbride/rails-surrender-demo)
repository. It provides several models and endpoints demonstrating a working configuration of `rails-surrender`.  The 
project provides seed data and a Postman collection to quickly experiment with the features of `rails-surrender`.


## Installation

This project is intended to be used in a Ruby on Rails project. To install, simply add this your Gemfile:

```ruby
gem 'rails-surrender'
```

and bundle:

```sh
% bundle
```

## Setup
Surrender setup begins in your models. To enable rendering of models with this gem, the `surrenders` method is invoked
on your models with a list of attributes and associations to be rendered, along with (optional) additional attributes
or associations that API clients an request. The following keys are allowed, along with the list of attributes for that 
key.

* `attributes`: A list of model attributes to be rendered by default.
* `expands`: A list of model associations to be rendered by default.  An association is typically defined as a
Rails ActiveRecord `has_many` or `belongs_to` or similar method call.
* `available_attributes`: A list of model attributes that can be rendered with the `include` query parameter.
* `available_expands`: A list of model associations that can be rendered with the `include` query parameter.

An example invocation of the `surreners` method is provided below:
```ruby
  surrenders attributes: [:id, :title, :description, :status],
             available_attributes: [:created_at, :updated_at],
             expands: [:activities],
             available_expands: [:user]
```

To invoke surrender in your controllers, simply end your controller action with a call to `surrender` with the 
resource you wish to render. An example controller action is provided below:

```ruby
  def index
    books = Book.all
    surrender books
  end
```


### Additional Notes

Surrender prevents circular renderings by tracking the history of nested objects. If you have a `Book` model, 
for example, that _expands_ it's associated `Author` model, and the `Author` model expands it's associated `Books` then 
surrender will stop expanding the associations when it recognized that it has already rendered a parent resource of the
same class as the requested child association.

Surrender prevents un-authorized access to associated resources by invoking the `current_ability` rule-set from the 
CanCanCan gem, if it is used in your Rails project. If CanCanCan is not present it will allow full access to 
associated resources.
