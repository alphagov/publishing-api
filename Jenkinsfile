#!/usr/bin/env groovy

library("govuk")

node {
  // Run against the Postgres 13 Docker instance on GOV.UK CI
  govuk.setEnvar("TEST_DATABASE_URL", "postgresql://postgres@127.0.0.1:54313/publishing-api-test")

  govuk.buildProject(
    extraParameters: [
      stringParam(
        name: "CONTENT_STORE_BRANCH",
        defaultValue: "deployed-to-production",
        description: "The branch of content-store to test pacts against"
      ),
    ],
    // Run rake default tasks except for pact:verify as that is ran via
    // a separate GitHub action.
    overrideTestTask: { sh("bundle exec rake rubocop spec") },
    afterTest: {
      lock("publishing-api-$NODE_NAME-test") {
        govuk.setEnvar("GIT_COMMIT_HASH", govuk.getFullCommitHash())
        checkGeneratedSchemasAreUpToDate(govuk);
        checkSchemaDependentProjects();
        govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")
        govuk.setEnvar("PACT_CONSUMER_VERSION", "branch-${env.BRANCH_NAME}");
        publishPublishingApiPactTests();
        runContentStorePactTests(govuk);
      }
    },
    brakeman: true,
  )
}

def publishPublishingApiPactTests() {
  stage("Publish pacts") {
    withCredentials([[$class: "UsernamePasswordMultiBinding", credentialsId: "pact-broker-ci-dev",
      usernameVariable: "PACT_BROKER_USERNAME", passwordVariable: "PACT_BROKER_PASSWORD"]]) {
      withEnv(["PACT_TARGET_BRANCH=branch-${env.BRANCH_NAME}"]) {
        sshagent(["govuk-ci-ssh-key"]) {
          sh "bundle exec rake pact:publish:branch"
        }
      }
    }
  }
}

def runContentStorePactTests(govuk) {
  stage("Checkout content store") {
    sh("rm -rf tmp/content-store")
    sh("git clone https://github.com/alphagov/content-store.git tmp/content-store")
    dir("tmp/content-store") {
      sh("git checkout ${env.CONTENT_STORE_BRANCH}")
      govuk.bundleApp()
    }
  }

  lock("content-store-$NODE_NAME-test") {
    stage("Verify pact with content-store") {
      dir("tmp/content-store") {
        sh("bundle exec rake db:mongoid:drop")
        withCredentials([
          [
            $class: "UsernamePasswordMultiBinding",
            credentialsId: "pact-broker-ci-dev",
            usernameVariable: "PACT_BROKER_USERNAME",
            passwordVariable: "PACT_BROKER_PASSWORD"
          ]
        ]) {
          govuk.runRakeTask("pact:verify")
        }
      }
    }
  }
}

def checkGeneratedSchemasAreUpToDate(govuk) {
    stage("Check generated schemas are up-to-date") {
      govuk.runRakeTask("build_schemas")
      schemasAreUpToDate = sh(script: "git diff --exit-code", returnStatus: true) == 0

      if (!schemasAreUpToDate) {
        error("Changes to checked-in files detected after running 'rake build_schemas'. "
          + "If these are generated files, you might need to run 'rake build_schemas' "
          + "to ensure they are regenerated and push the changes.")
      }
    }
}

boolean schemasDirChangedInBranch(branchName) {
  noChangesToSchemasOnBranch = sh(script: "git diff --exit-code origin/main -- 'content_schemas/dist/' ${branchName} --  'content_schemas/dist/' ", returnStatus: true) == 0
  return !noChangesToSchemasOnBranch
}

def checkSchemaDependentProjects() {
// Run schema tests outside of 'node' definition, so that they do not block the
// original executor while the downstream tests are being run
    stage("Check dependent projects against updated schema") {
      def dependentBuilds = [:]

      def schemasDependentApplications = [
        'collections-publisher',
        'collections',
        'contacts',
        'content-data-api',
        'content-publisher',
        'content-store',
        'content-tagger',
        'email-alert-frontend',
        'email-alert-service',
        'feedback',
        'finder-frontend',
        'frontend',
        'government-frontend',
        'hmrc-manuals-api',
        'info-frontend',
        'licencefinder',
        'manuals-publisher',
        'publisher',
        'search-api',
        'search-admin',
        'service-manual-frontend',
        'service-manual-publisher',
        'short-url-manager',
        'smartanswers',
        'specialist-publisher',
        'static',
        'travel-advice-publisher',
        'whitehall',
      ]

      if ( schemasDirChangedInBranch(env.BRANCH_NAME) ) {

        for (dependentApp in schemasDependentApplications) {
          // Dummy parameter to prevent mutation of the parameter used
          // inside the closure below. If this is not defined, all of the
          // builds will be for the last application in the array.
          def app = dependentApp

          dependentBuilds[app] = {
            start = System.currentTimeMillis()

            build job: "/${app}/deployed-to-production",
              parameters: [
                [$class: 'BooleanParameterValue',
                  name: 'IS_SCHEMA_TEST',
                  value: true],
                [$class: 'StringParameterValue',
                  name: 'SCHEMA_BRANCH',
                  value: env.BRANCH_NAME],
                [$class: 'StringParameterValue',
                  name: 'SCHEMA_COMMIT',
                  value: env.GIT_COMMIT_HASH]
              ], wait: false
          }
        }

      parallel dependentBuilds

      } else {
        echo "no changes to schemas detected, skipping dependent apps stage"
      }
    }
}

