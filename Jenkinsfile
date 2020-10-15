#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.6") {

  govuk.buildProject(
    extraParameters: [
      stringParam(
        name: "CONTENT_STORE_BRANCH",
        defaultValue: "deployed-to-production",
        description: "The branch of content-store to test pacts against"
      ),
      stringParam(
        name: "PUBLISHING_E2E_TESTS_BRANCH",
        defaultValue: "test-against",
        description: "The branch of publishing-e2e-tests to test against"
      )
    ],
    beforeTest: {
      setExtraEnvVars(govuk);
    },

    publishingE2ETests: true,
    afterTest: {
      publishCoverage(govuk);

      lock("publishing-api-$NODE_NAME-test") {
        publishPublishingApiPactTests(govuk);

        runContentStorePactTests(govuk);
      }
    },
    brakeman: true,
    rubyLintDiff: false,
  )
}

def setExtraEnvVars(govuk) {
  // enable coverage reporting in tests
  govuk.setEnvar("RCOV", "1")
  // setup pact broker url for pact tests
  govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")
}

def publishCoverage(_govuk) {
  stage("Publish coverage") {
    publishHTML(target: [
      allowMissing: false,
      alwaysLinkToLastBuild: false,
      keepAll: true,
      reportDir: "coverage",
      reportFiles: "index.html",
      reportName: "Coverage Report"
    ])
  }
}

def publishPublishingApiPactTests(_govuk) {
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
          govuk.runRakeTask("pact:verify:branch[${env.BRANCH_NAME}]")
        }
      }
    }
  }
}
