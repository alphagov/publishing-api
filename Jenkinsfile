#!/usr/bin/env groovy

REPOSITORY = 'publishing-api'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  try {
    stage("Build") {
      checkout scm
      govuk.cleanupGit()
      govuk.mergeMasterBranch()
      govuk.bundleApp()
      govuk.contentSchemaDependency()
      govuk.setEnvar("GOVUK_CONTENT_SCHEMAS_PATH", "tmp/govuk-content-schemas")
      govuk.setEnvar("RAILS_ENV", "test")
      govuk.setEnvar("RCOV", "1")
      govuk.setEnvar("PACT_BROKER_BASE_URL", "https://pact-broker.dev.publishing.service.gov.uk")
      sh('bin/rails db:environment:set')
      sh('bundle exec rake db:drop db:create db:schema:load')
    }

    stage("Lint") {
      govuk.rubyLinter('app config Gemfile lib spec')
    }

    stage("Test") {
      sh "bundle exec rspec"
    }

    stage("Verify pact") {
      sh "bundle exec rake pact:verify"
    }

    stage("Publish results") {
      withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'pact-broker-ci-dev',
        usernameVariable: 'PACT_BROKER_USERNAME', passwordVariable: 'PACT_BROKER_PASSWORD']]) {
        withEnv(["PACT_TARGET_BRANCH=branch-${env.BRANCH_NAME}"]) {
          sshagent(['govuk-ci-ssh-key']) {
            sh "bundle exec rake pact:publish:branch"
          }
        }
      }

      publishHTML(target: [
        allowMissing: false,
        alwaysLinkToLastBuild: false,
        keepAll: true,
        reportDir: 'coverage/rcov',
        reportFiles: 'index.html',
        reportName: 'RCov Report'
      ])
    }

    if (env.BRANCH_NAME == 'master') {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      stage("Deploy on Integration") {
        govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
