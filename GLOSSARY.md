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

**Menu**:
Everything a request may ask of one model: its **field menu** and its **selection menu**.
_Avoid_: Options, offer, catalog, docs, schema, metadata, capabilities

**Field menu**:
The **default** and **available fields** of one model, nested by **expand**. It applies wherever the model renders, at the top of a response or inside an expand.

### Records

**Selection**:
The records one request renders, picked from what the controller surrenders by the request's **filter**, **sort** and **page**.
_Avoid_: Query, scope, listing

**Filter**:
A condition a request puts on the records it selects, named for a field or for a filter the model defines.

**Sort**:
The order a request puts its selected records in, by one attribute, an attribute of an association, or a sort the model defines.
_Avoid_: Order

**Page**:
One slice of a selection, set by `page` and `per`. Selections are paged unless the controller skips it.
_Avoid_: Pagination window

**Page size**:
How many records one **page** holds: the request's `per`, or the default page size when it asks for none, capped at the **page size limit**.
_Avoid_: Per page, limit

**Page size limit**:
The most records one **page** may hold, whatever a request asks for. An app sets it, or removes it.
_Avoid_: Max per page

**Selection menu**:
The **filters**, **sorts** and **page size** a request may use to pick a model's records. It applies only at the top of a response, to a relation: nothing filters or sorts the records inside an expand.

**Count response**:
The number of records a request's filters select, ignoring the page, rendered instead of the records.

**Endpoint menu**:
What one endpoint accepts: its model's **menu** with the controller's **include** and **exclude** applied, and no **selection menu** for a single record. Rendered instead of the records when a request asks for it, like a **count response**.

### Asks

**Include**:
A list of fields, optionally nested by **expand**, added to what renders. A request may include only **available fields**; a controller may include any field.

**Exclude**:
A list of fields, optionally nested by **expand**, removed from what renders. A request's **include** wins over an exclude of the same field.
