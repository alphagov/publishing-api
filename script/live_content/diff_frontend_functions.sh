#!/usr/bin/env bash

function curl_and_strip_hashes() {
  while [ $# -gt 0 ]; do
    case $1 in
      --app) { is_option_name $2 && shift; } || { local app=$2; shift 2; };;
      --curl-path) local curl_path=$2; shift 2;;
      --environment)
        case $2 in
          # this means we now need to specify the curl path before the
          # environment when using the dev environment
          d|development) local domain="http://dev.gov.uk";;
          i|integration) local domain='https://www.integration.publishing.service.gov.uk';;
          p|production) local domain='https://www.gov.uk';;
          s|staging) local domain='https://www.staging.publishing.service.gov.uk';;
          *) echo 'Argument error: environment must be i[ntegration], s[taging], or p[roduction].'; exit;;
        esac
        shift 2
        ;;
      --output-path) local output_path=$2; shift 2;;
      --password) { is_option_name $2 && shift; } || { local password=$2; shift 2; };;
      --username) { is_option_name $2 && shift; } || { local username=$2; shift 2; };;
    esac
  done

  if [[ -n $app ]]; then
    local domain=$(echo $domain | sed "s;\(http://\);\1$app.;")
  fi

  local response
  response=$(curl -u "$username:$password" "$domain$curl_path") || exit 1

  echo $response | sed -r \
    -e 's/\?graphql=true//g' \
    -e 's/nonce="[^"]{22}=="/nonce="HASH=="/g' \
    -e 's/ (aria-labelledby|for|id)="([^"]+)-[a-z0-9]{8}"/ \1="\2-HASH"/g' \
    -e 's/<(meta name="govuk:updated-at" content=)"[^"]+">/<\1"TIMESTAMP">/' \
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
      tmp/diffs/frontend/content_store_response.html \
      tmp/diffs/frontend/publishing_api_response.html
  else
    diff \
      --color=always \
      ${style_flags:+"$style_flags"} \
      tmp/diffs/frontend/content_store_response.html \
      tmp/diffs/frontend/publishing_api_response.html
  fi
}

function prepare_html() {
  while [ $# -gt 0 ]; do
    case $1 in
      --base-path) local base_path=$2; shift 2;;
      --environment) local environment=$2; shift 2;;
      --password) { is_option_name $2 && shift; } || { local password=$2 && shift 2; };;
      --username) { is_option_name $2 && shift; } || { local username=$2 && shift 2; };;
    esac
  done

  case $environment in
    --d|development) local app=$(govuk-docker-run bundle exec rails runner \
      script/live_content/rendering_app.rb "$base_path")
  esac

  mkdir -p "tmp/diffs/frontend"

  curl_and_strip_hashes \
    --output-path tmp/diffs/frontend/content_store_response.html \
    --app "$app" \
    --environment "$environment" \
    --curl-path "$base_path?graphql=false" \
    --username "$username" \
    --password "$password"

  curl_and_strip_hashes \
    --output-path tmp/diffs/frontend/publishing_api_response.html \
    --app "$app" \
    --environment "$environment" \
    --curl-path "$base_path?graphql=true" \
    --username "$username" \
    --password "$password"
}

function is_option_name() {
  echo $1 | grep "^--[^-]"
}
