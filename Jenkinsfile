#!/usr/bin/env groovy

library("govuk")

node {
  govuk.checkoutFromGitHubWithSSH("publishing-api")
  sh("bundle config set --local path '/var/lib/jenkins/bundles'")
  sh("bundle install")
}
