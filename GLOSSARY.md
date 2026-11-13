# Surrender

Surrender renders ActiveRecord resources as JSON, shaped by query params a request sends and options a controller passes.

## Language

### Fields

**Field**:
A name a model can render: an attribute, a method, an association, or an id list of an association such as `chapter_ids`.
_Avoid_: Column, property

**Default field**:
A field a model renders without being asked, declared by `surrenders`.

**Available field**:
A field a request may add with **include**, declared by `surrenders ... available:`.
_Avoid_: Callable field

**Id list**:
A field that names an association by its ids, such as `chapter_ids`, and renders as a flat list of them.
_Avoid_: Association ids, ids attribute

**Expand**:
A field that names an association and renders as the nested resource, rather than as a value.
_Avoid_: Expansion, join

**Field tree**:
The fields one request renders, nested by **expand**, worked out from the model, the request and the controller before any record loads.
_Avoid_: Render plan, configuration, inclusion map

### Asks

**Include**:
A list of fields, optionally nested by **expand**, added to what renders. A request may include only **available fields**; a controller may include any field.

**Exclude**:
A list of fields, optionally nested by **expand**, removed from what renders. A request's **include** wins over an exclude of the same field.
