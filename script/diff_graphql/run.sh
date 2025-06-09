#!/usr/bin/env bash

# Diff a rendered page in production when the data source is Content Store vs
# when the data source is Publishing API's GraphQL endpoint.

source script/diff_graphql/functions.sh

while [[ "$download_html" != @(y|yes|n|no) ]]; do
  read -p 'Download HTML (y[es]/n[o])? ' download_html
done

if [[ $download_html == @(y|yes) ]]; then
  while [ -z "$base_path" ]; do
    read -p 'Enter base path (e.g. "/world"): ' base_path
  done

  while [[ $environment != @(i|integration|s|staging|p|production) ]]; do
    read -p 'Enter environment (i[ntegration]/s[taging]/p[roduction]): ' environment
  done

  if [[ $environment == @(i|integration) ]]; then
    while [ -z "$username" ]; do
      read -p 'Enter username: ' username
    done

    while [ -z "$password" ]; do
      read -s -p 'Enter password: ' password
    done
  fi

  mkdir -p tmp/diff_graphql

  echo ''
  prepare_html \
    --base-path "$base_path" \
    --environment "$environment" \
    --username "$username" \
    --password "$password"
  echo ''
fi

diff_html --interactive
