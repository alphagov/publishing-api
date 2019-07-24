# Contract testing with Pact

Publishing API uses contract testing via the [Pact library][pact] to verify its
API.

Pact allows the consumer of an API to make assertions about the requests it will
make to that API and the response it expects back. In the case of Publishing
API, all requests from other apps are made via the gds-api-adapters gem, so
the pact is defined as being between gds-api-adapters and publishing-api.
What this means is:

- the expected interactions are defined in the [publishing_api_v2_test.rb in
  gds-api-adapters][gds-api-adapters-publishing-api-tests]
- when these tests are run they output a JSON pactfile which is published to
  [the pact broker][pact-broker]
- the build of publishing api will use this pactfile to test the publishing-api
  service


## How it works

The gds-api-adapters gem, as the consumer of the pact, includes in its test
suite a fake publishing-api endpoint provided by the pact gem. The tests then
specify the requests the consumer will make against that endpoint, along with
the data it will send for each request and the response it expects to that
request.

When the tests suite is successfully run, a JSON file is output that contains
the details of these requests and their expected results. This can then be
replayed against the real Publishing API application to test that it behaves as
expected.


## How the tests run in CI

The CI environment includes an app called [Pact Broker][pact-broker]. This app
records versions of pacts and supplies them on request, to allow verifying
against different versions.

The gds-api-adapters Jenkins job runs the tests, then pushes the generated JSON
file to the broker as `branch-<branch-name>` using the `pact:publish:branch`
rake task. It then checks out the master branch of publishing-api and verifies
the pact against that branch using the `pact:verify:branch` rake task.

In publishing-api itself, the Jenkins job runs the `pact:verify` rake task to
verify the current branch against the master branch.


## Running the pacts in development

You can use `pact:verify` locally to run the current branch against the master
branch of pacts stored in Pact Broker. If you need to run them against a local
version of gds-api-adapters, run the tests in that directory
and then set the `USE_LOCAL_PACT` env variable:

    USE_LOCAL_PACT=1 bundle exec rake pact:verify

This will cause pact to look for the pactfile in
`../gds-api-adapters/spec/pacts/gds_api_adapters-publishing_api.json`. You can
additionally override this location by setting the `GDS_API_PACT_PATH` variable.


## Making breaking changes

It is possible to get into a situation where there are mutually dependent
branches of gds-api-adapters and publishing-api, neither of which will pass
their tests on CI until the other is merged. In this case, it is
possible to run the gds-api-adapters branch on Jenkins against a manually
specified branch of publishing-api, by manually running the branch build and
entering the relevant branch name as the `PUBLISHING_API_BRANCH` parameter.
This will allow Jenkins to report a successful test run and let the branch be
merged.


[pact]: https://github.com/realestate-com-au/pact
[gds-api-adapters-publishing-api-tests]: https://github.com/alphagov/gds-api-adapters/blob/master/test/publishing_api_v2_test.rb
[pact-broker]: https://pact-broker.cloudapps.digital/
