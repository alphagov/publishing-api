#!/usr/bin/env bash

function curl_and_strip_hashes() {
  while [ $# -gt 0 ]; do
    case $1 in
      --curl-path) local curl_path=$2; shift 2;;
      --environment)
        case $2 in
          i|integration) local domain='https://www.integration.publishing.service.gov.uk';;
          p|production) local domain='https://www.gov.uk';;
          s|staging) local domain='https://www.staging.publishing.service.gov.uk';;
          *) echo 'Argument error: environment must be i[ntegration], s[taging], or p[roduction].'; exit;;
        esac
        shift 2
        ;;
      --output-path) local output_path=$2; shift 2;;
      --password) local password=$2; shift 2;;
      --username) local username=$2; shift 2;;
    esac
  done

  curl -u "$username:$password" "$domain$curl_path" \
    | sed -r \
        -e 's/\?graphql=true//g' \
        -e 's/nonce="[^"]{22}=="/nonce="HASH=="/g' \
        -e 's/ (aria-labelledby|for|id)="([^"]+)-[a-z0-9]{8}"/ \1="\2-HASH"/g' \
        -e 's/<meta name="govuk:updated-at" content=".*">/<meta name="govuk:updated-at" content="TIMESTAMP">/' \
        -e '/<meta name="govuk:content-has-history" content=".*">/d' \
        -e 's/(This news article was withdrawn on &lt;time datetime=)"[^"]+"/\1"TIMESTAMP"/' \
        -e 's/(This news article was withdrawn on <time datetime=)"[^"]+"/\1"TIMESTAMP"/' \
    > "$output_path"
}

function diff_html() {
  while [ $# -gt 0 ]; do
    case $1 in
      --diff-style) diff_style=$2; shift 2;;
      --interactive)
        read -p 'Enter diff style (n[ormal]/i[nline]/s[ide-by-side]/u[nified]): ' diff_style
        echo ''
        shift
        ;;
    esac
  done

  case $diff_style in
    i|inline) git_diff=true;;
    s|side-by-side) style_flags='-y --suppress-common-lines';;
    u|unified) style_flags='-u';;
    *) style_flags='';;
  esac

  if [[ $git_diff = true ]]; then
    git diff \
      --no-index \
      --word-diff=color \
      tmp/diff_graphql/content_store_response.html \
      tmp/diff_graphql/graphql_response.html
  else
    diff \
      --color=always \
      ${style_flags:+"$style_flags"} \
      tmp/diff_graphql/content_store_response.html \
      tmp/diff_graphql/graphql_response.html
  fi
}

function prepare_html() {
  while [ $# -gt 0 ]; do
    case $1 in
      --base-path) local base_path=$2; shift 2;;
      --environment) local environment=$2; shift 2;;
      --password) local password=$2; shift 2;;
      --username) local username=$2; shift 2;;
    esac
  done

  curl_and_strip_hashes \
    --curl-path "$base_path" \
    --output-path tmp/diff_graphql/content_store_response.html \
    --environment "$environment" \
    --username "$username" \
    --password "$password"

  curl_and_strip_hashes \
    --curl-path "$base_path?graphql=true" \
    --output-path tmp/diff_graphql/graphql_response.html \
    --environment "$environment" \
    --username "$username" \
    --password "$password"
}
