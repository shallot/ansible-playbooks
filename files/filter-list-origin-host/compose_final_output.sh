#!/bin/sh -e

prepdir={{ filter_list_origin_final_output }}_prep
finaldir={{ filter_list_origin_final_output }}

link_globs=$@

rm -rf $prepdir
mkdir $prepdir

# this comes from update_repos.sh + sitescripts.subscriptions.bin.updateSubscriptionDownloads
cp -a {{ filter_list_origin_outputs }}/data/. $prepdir/

# this comes from update_repos.sh + compress_files.sh
cp -a {{ filter_list_origin_outputs }}/gzip/. $prepdir/

# this comes from fetch_gitlab_artifacts.sh
cp -a {{ filter_list_origin_outputs }}/gitlab_artifacts/. $prepdir/

# this comes from fetch_gstorage_artifacts.sh
cp -a {{ filter_list_origin_outputs }}/gstorage_artifacts/. $prepdir/

# this replaces regular files with links to subdir files, if they exist
{{ filter_list_origin_base_dir }}/compound_webroot_structure.sh $prepdir "$link_globs"

rm -rf $finaldir.old
test ! -d $finaldir || mv $finaldir $finaldir.old
# minimal race condition is here - this is where we don't want anyone reading from $finaldir
# but rsync --max-delete=anything on filter-servers protects us from downtime here
mv $prepdir $finaldir

# $finaldir is referenced from ssh forced command
