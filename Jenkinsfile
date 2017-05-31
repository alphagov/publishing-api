#!/usr/bin/env groovy

REPOSITORY = "publishing-api"
DEFAULT_SCHEMA_BRANCH = "deployed-to-production"
DEFAULT_CONTENT_STORE_BRANCH = "deployed-to-production"
DEFAULT_PUBLISHING_E2E_TESTS_BRANCH = "master"

node {
  def govuk = load("/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy")

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: "10"
      )
    ),
    parameters([
      booleanParam(
        name: "IS_SCHEMA_TEST",
        defaultValue: false,
        description: "Identifies whether this build is being triggered to test a change to the content schemas"
      ),
      stringParam(
        name: "SCHEMA_BRANCH",
        defaultValue: DEFAULT_SCHEMA_BRANCH,
        description: "The branch of govuk-content-schemas to test against"
      ),
      stringParam(
        name: "CONTENT_STORE_BRANCH",
        defaultValue: DEFAULT_CONTENT_STORE_BRANCH,
        description: "The branch of content-store to test pacts against"
      ),
      stringParam(
        name: "PUBLISHING_E2E_TESTS_BRANCH",
        defaultValue: DEFAULT_PUBLISHING_E2E_TESTS_BRANCH,
        description: "The branch of publishing-e2e-tests to test against"
      ),
    ])
  ])

  try {
    govuk.initializeParameters([
      "IS_SCHEMA_TEST": "false",
      "SCHEMA_BRANCH": DEFAULT_SCHEMA_BRANCH,
      "CONTENT_STORE_BRANCH": DEFAULT_CONTENT_STORE_BRANCH,
      "PUBLISHING_E2E_TESTS_BRANCH": DEFAULT_PUBLISHING_E2E_TESTS_BRANCH,
    ])

    if (!govuk.isAllowedBranchBuild(env.BRANCH_NAME)) {
      return
    }

    stage("Build") {
      checkout(scm)
      govuk.cleanupGit()
      govuk.mergeMasterBranch()
      govuk.bundleApp()
      govuk.contentSchemaDependency(env.SCHEMA_BRANCH)
      govuk.setEnvar("GOVUK_CONTENT_SCHEMAS_PATH", "tmp/govuk-content-schemas")
      govuk.setEnvar("RAILS_ENV", "test")
      govuk.setEnvar("DISABLE_DATABASE_ENVIRONMENT_CHECK", "1")
      govuk.setEnvar("RCOV", "1")
      govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.cloudapps.digital")
      govuk.setEnvar("FULL_COMMIT_HASH", sh(
        script: "git rev-parse HEAD",
        returnStdout: true
      ).trim())
      govuk.buildDockerImage(REPOSITORY, env.BRANCH_NAME)
    }

    stage("Lint") {
      govuk.rubyLinter("app config Gemfile lib spec")
    }

    // Prevent a project's tests from running in parallel on the same node
    lock("publishing-api-$NODE_NAME-test") {
      stage("Build DB") {
        sh("bundle exec rake db:reset")
      }

      stage("Test") {
        sh("bundle exec rspec")
      }
    }

    stage("Publish coverage") {
      publishHTML(target: [
        allowMissing: false,
        alwaysLinkToLastBuild: false,
        keepAll: true,
        reportDir: "coverage/rcov",
        reportFiles: "index.html",
        reportName: "RCov Report"
      ])
    }

    stage("End-to-end tests") {
      build(
        job: "publishing-e2e-tests/${env.PUBLISHING_E2E_TESTS_BRANCH}",
        parameters: [
          [$class: "StringParameterValue",
            name: "PUBLISHING_API_COMMITISH",
            value: env.FULL_COMMIT_HASH],
          [$class: "StringParameterValue",
            name: "ORIGIN_REPO",
            value: "publishing-api"],
          [$class: "StringParameterValue",
            name: "ORIGIN_COMMIT",
            value: env.FULL_COMMIT_HASH]
        ],
        wait: false,
      )
    }

    stage("Verify pact") {
      sh "bundle exec rake pact:verify"
    }

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

    releaseTag = "release_${env.BUILD_NUMBER}"

    stage("Push Docker image") {
      tag = env.BRANCH_NAME == "master" ? releaseTag : null
      govuk.pushDockerImage(REPOSITORY, env.BRANCH_NAME, tag)
    }

    if (env.BRANCH_NAME == "master") {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, releaseTag)
      }

      stage("Deploy on Integration") {
        govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, "release", "deploy")
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: "Mailer",
          notifyEveryUnstableBuild: true,
          recipients: "govuk-ci-notifications@digital.cabinet-office.gov.uk",
          sendToIndividuals: true])
    throw e
  }
}
