#!/usr/bin/env bash

# Using a list of base paths, render each page with Content Store and Publishing
# API's GraphQL endpoint as the data source and diff the results.

source script/diff_graphql/functions.sh

diff_style='normal'
max_diffs=0
output_dir='tmp/diff_graphql/diffs'
help_text="script/diff_graphql/bulk.sh

DESCRIPTION
     Using a list of base paths, render each page with Content Store and
     Publishing API's GraphQL endpoint as the data source and diff the results.

ARGUMENTS
     --base-paths-file-path (required)
             Path to a file containing a list of base paths (e.g. /world). There
             should be one base path per line and an empty line at the end of
             the file.

     --diff-style
             A style for the diff. Supports three different styles:

             i or inline
                     A diff with changes shown inline where possible.

             s or side-by-side
                     A side-by-side view of changed lines. Long lines will be
                     truncated.

             u or unified
                     A diff with before/after lines in the same section and a
                     few lines of context.

             default (any other value)
                     A standard diff, where for each change the before lines
                     precede the after lines without any context.

     --environment (required)
             The environment to which requests should be sent. One of:

             i       Integration
             s       Staging
             p       Production

     --max-diffs
             If the number of pages with non-empty diffs reaches the specified
             maximum, the script will exit. By default, there's no limit.

     --output-dir
             Where to save the diff files. The script will output one diff file
             per provided base path. By default this is tmp/diff_graphql.

     --password (required when environment is integration or staging)
             The password required to access the publishing service on the given
             environment.

     --username (required when environment is integration or staging)
             The username required to access the publishing service on the given
             environment."
usage_text="
usage: script/diff_graphql/bulk.sh [--diff-style style]
                                   [--max-diffs number]
                                   [--output-dir path/to/dir]
                                   --base-paths-file-path path/to/file
                                   --environment p
       script/diff_graphql/bulk.sh [--diff-style style]
                                   [--max-diffs number]
                                   [--output-dir path/to/dir]
                                   --base-paths-file-path path/to/file
                                   --environment i
                                   --username username
                                   --password password
       script/diff_graphql/bulk.sh --help"

while [ $# -gt 0 ]; do
  case $1 in
    --base-paths-file-path) base_paths_file_path=$2; shift 2;;
    --diff-style) diff_style=$2; shift 2;;
    --environment) environment=$2; shift 2;;
    --help) echo "$help_text"; exit;;
    --max-diffs) max_diffs=$2; shift 2;;
    --output-dir) output_dir=$2; shift 2;;
    --password) password=$2; shift 2;;
    --username) username=$2; shift 2;;
    *) echo "$usage_text"; exit 1;;
  esac
done

if [[ -z $base_paths_file_path || -z $environment ]]; then
  echo "$usage_text"
  exit 1
fi

if [[ $environment != @(i|integration|s|staging|p|production) ]]; then
  echo "$usage_text"
  exit 1
fi

if [[ $environment == @(i|integration) ]] && [[ -z "$username" || -z "$password" ]]; then
  echo "$usage_text"
  exit 1
fi

mkdir -p "$output_dir"

diff_count=0

while read -r base_path; do
  output_path="$output_dir/$(echo "$base_path" | sed 's/^\///' | sed 's/\//__/g')"
  echo -n "" > "$output_path"
  echo -e "Processing $base_path\n"
  prepare_html \
    --base-path "$base_path" \
    --environment "$environment" \
    --username "$username" \
    --password "$password"

  if diff_html --diff-style "$diff_style" >> "$output_path"; then
    rm "$output_path"
  else
    echo -e "$base_path\n\n$(cat "$output_path")" > "$output_path"

    diff_count=$((diff_count + 1))

    if [ "$max_diffs" -ne 0 ] && [ $diff_count -ge "$max_diffs" ]; then
      echo -e "\nMax diffs ($max_diffs) reached. Exiting script."
      exit 1
    fi
  fi

  echo -e "\nProcessed $base_path\nJust a second...\n"
  sleep 1
done < "$base_paths_file_path"

echo "Finished!"
