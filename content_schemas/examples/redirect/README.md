# Redirect format

This format is used to create/update redirect(s) for a given base path. The
Publishing API will register the provided redirect(s) with the router.

Note that this schema has a restricted set of properties at the metadata level,
and no details or links hashes at all. Therefore, it is not constructed by
combining sub-schemas. In addition, there is no frontend version, because
redirects are never seen by the frontend: everything is handled by the router.

## Attributes of redirect and effects on behaviour

### Route types

#### `exact`
Match exact URL only.

#### `prefix`
Match URL and all sub-paths.

### Segments modes

#### `ignore`
##### when used with `exact`
For source `/from?q=123` and target url `/target`, will redirect to `/target`

##### when used with `prefix`
For source `/from?q=123` and target url `/target`, will redirect to `/target` and also `/from/doe/a/deer` will redirect to `/target`

#### `preserve`
##### when used with `exact`
For source `/from/?q=123` and target url `/target` will redirect to `/target?q=123`</p>

##### when used with `prefix`
For source `/from/?q=123` and target url `/target` will redirect to `/target/page/?q=123` and also `/from/doe/a/deer` will redirect to `/target/doe/a/deer`
