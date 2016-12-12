#!/usr/bin/env groovy

REPOSITORY = 'publishing-api'

node {
   def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

   try {
      stage("Checkout") {
         checkout scm
      }

      stage("Build") {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'pact-broker-ci-dev',
                   usernameVariable: 'PACT_BROKER_USERNAME', passwordVariable: 'PACT_BROKER_PASSWORD']]) {
          def pact_branch = (env.BRANCH_NAME == 'master' ? 'master' : "branch-${env.BRANCH_NAME}")
          withEnv(["PACT_TARGET_BRANCH=${pact_branch}"]) {
            sshagent(['govuk-ci-ssh-key']) {
              sh "${WORKSPACE}/jenkins.sh"
            }
          }
        }
      }

      stage("Push release tag") {
         echo 'Pushing tag'
         govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      // Deploy on Integration (only master)
      govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
   } catch (e) {
      currentBuild.result = "FAILED"
      step([$class: 'Mailer',
            notifyEveryUnstableBuild: true,
            recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
            sendToIndividuals: true])
      throw e
   }
}
