# Special route format

This format is used to reserve & register URLs for a given base path.
These will be typically registering special-case routes such as

- static files (robots.txt, google verification pages)
- legacy prefixes (/government, /info)
- /search, /, etc

reducing the chance of major routes such as /government being accidentally
overwritten when publishing other content.

These documents will be published by the relevant owning applications on deploy.

The hope is that many of these routes will be handled by a more traditional
publisher in the future, but there is no current plan for implementing that.

Note that this schema has no frontend version because it represents unique pages
such as the homepage or search results which are not generated from a single
content item.
