#!/usr/bin/env bash

# Filter a list of base paths by one or more given schema names.

data_dir='tmp/diff_graphql'
schema_names=()
help_text="script/diff_graphql/filter_base_paths.sh

DESCRIPTION
     Filter a list of base paths by one or more given schema names.

ARGUMENTS
     --schema-names (required)
             A list of schema names to filter by (e.g. role or news_article).

     --data-dir
             The directory in which you've stored the \"unfiltered_base_paths\"
             file and where the \"filtered_base_paths\" file will be written. By
             default this is tmp/diff_graphql

     --translated-only
             Filters out base paths for pages in English.

     --with-content-store
             Filter base paths using Content Store instead of Publishing API."
usage_text="
usage: script/diff_graphql/filter_base_paths.sh [--data-dir path/to/data/dir]
                                                --schema_names schema_name_1
                                                [scema_name_2...]"

while [ $# -gt 0 ]; do
  case $1 in
    --data-dir) data_dir=$2; shift 2;;
    --help) echo "$help_text"; exit;;
    --schema-names)
      shift

      while [[ $# -gt 0 && $1 != --* ]]; do
        schema_names+=("$1")
        shift
      done

      ;;
    --translated-only) translated_only=true; shift;;
    --with-content-store) with_content_store=true; shift;;
    *) echo "$usage_text"; exit 1;;
  esac
done

if [ ! -r "$data_dir/unfiltered_base_paths" ]; then
  echo "Error: $data_dir/unfiltered_base_paths not found"
  exit 1
fi

if [ ${#schema_names[@]} -eq 0 ]; then
  echo "$usage_text"
  exit 1
fi

sed -i '' -r -e '/^"url_path"$/d' -e 's/"//g' "$data_dir/unfiltered_base_paths"

echo "Unfiltered base paths: $(grep -c '^' "$data_dir/unfiltered_base_paths")"

if [[ $translated_only = true ]]; then
  echo -e '\nFiltering out untranslated content'
  grep -E '^.+\.[a-zA-Z]{2}(-[a-zA-Z0-9]{2,3})?$' "$data_dir/unfiltered_base_paths" > script/diff_graphql/unfiltered_base_paths
else
  cp "$data_dir/unfiltered_base_paths" script/diff_graphql/unfiltered_base_paths
fi

if [[ $with_content_store = true ]]; then
  mkdir -p ../content-store/script/diff_graphql
  cp script/diff_graphql/{unfiltered_base_paths,filter_base_paths.rb} ../content-store/script/diff_graphql

  cd ../content-store || exit 1
  govuk-docker-run bundle exec rails runner script/diff_graphql/filter_base_paths.rb "${schema_names[@]}"
  cd - > /dev/null || exit 1

  mv ../content-store/script/diff_graphql/filtered_base_paths script/diff_graphql/filtered_base_paths
  rm -rf ../content-store/script/diff_graphql
else
  govuk-docker-run bundle exec rails runner script/diff_graphql/filter_base_paths.rb "${schema_names[@]}"
fi

mv script/diff_graphql/filtered_base_paths "$data_dir/filtered_base_paths"
rm script/diff_graphql/unfiltered_base_paths

echo -e "\nFiltered base paths written to $data_dir/filtered_base_paths"
