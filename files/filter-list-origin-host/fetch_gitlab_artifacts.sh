#!/bin/sh -e

if [ ! -d "$1" ]; then
  echo "$1 not a directory, aiee" >&2
  exit 1
fi
input="$1"

if [ ! -d "$2" ]; then
  echo "$2 not a directory, aiee" >&2
  exit 1
fi
output="$2"

for project_file in $(find $input -maxdepth 1 -type f); do
  # project will be e.g. eyeo%2Fdevops%2Fansible-playbooks
  ref=$(cat $project_file)
  project=$(basename $project_file)
  current_pipeline_id=$(curl -sS -H "Content-Type: application/json" \
                              'https://gitlab.com/api/v4/projects/'$project'/pipelines' | \
                          jq -r \
                             'map(select(.ref=="'$ref'" and .status=="success")) | first | .id')
  current_job_id=$(curl -sS -H "Content-Type: application/json" \
                           'https://gitlab.com/api/v4/projects/'$project'/pipelines/'$current_pipeline_id'/jobs' | \
                     jq -r \
                        'map(select(.ref=="'$ref'" and .status=="success")) | first | .id')
  fetch_dir=$input/${project}.fetched
  test -d $fetch_dir || mkdir $fetch_dir
  curl -sS -L \
       --output $fetch_dir/artifacts.zip \
       'https://gitlab.com/api/v4/projects/'$project'/jobs/'$current_job_id'/artifacts'
  # extract without subdirectory names, overwrite all
  7za e -aoa -o$output $fetch_dir/artifacts.zip
done

$(dirname $0)/compress_files.sh $output $output
