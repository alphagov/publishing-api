# Publishing API

This is a Go application that proxies requests to multiple content-stores. Our
use case for this is to keep two copies of the frontend of GOV.UK running: one
which the public sees and another which is only used by people working on
content to review work in progress.

Publishing apps will talk to the publishing-api rather than the content-store.
Normal publishing requests are forwarded to both the live and draft
content-stores, whereas draft documents would only be forwarded to the draft
content-store.

### Dependencies

- [alphagov/url-arbiter](https://github.com/alphagov/url-arbiter) - publishing-api will take over content-store's job of updating url-arbiter. This is to prevent race conditions as two content-stores try to register with the same url-arbiter.
- [alphagov/content-store](https://github.com/alphagov/content-store) - publishing-api's function is to proxy requests to multiple content-stores (eg a draft and a live content-store)
- [gom](https://github.com/mattn/gom) - to vendorise dependencies

### Running the application

`make run`

Dependencies will be dowloaded and installed and the app should start up on
port 3093. Currently on GOV.UK machines it also be available at
`publishing-api-temp.dev.gov.uk`, but this will change to
`publishing-api.dev.gov.uk` in the near future.

## Running the test suite

You can run the tests locally with: `make`. This will use the gom tool to
vendorise dependencies into a folder within the project.

You can download the gom tool by running:
`go get github.com/mattn/gom`.

### Example API requests

``` sh
curl https://publishing-api-temp.production.alphagov.co.uk/content<base_path> -X PUT \
    -H 'Content-type: application/json' \
    -d '<content_item_json>'
```

See the documentation for [content-store](https://github.com/alphagov/content-store) for full details.

## Licence

[MIT License](LICENCE)
