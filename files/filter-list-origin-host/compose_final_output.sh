#!/bin/sh -e

prepdir={{ filter_list_origin_final_output }}_prep
finaldir={{ filter_list_origin_final_output }}

rm -rf $prepdir
mkdir $prepdir

for subscription in {{ filter_list_origin_compress_subscriptions }}
do
  cp -a {{ filter_list_origin_inputs }}/$subscription/* $prepdir/
done

# removed because it was copying files without pre-processing -joy, 2021-12-13
# cp -a {{ filter_list_origin_inputs }}/crumbsfilterlist/crumbs-privacy-friendly.txt $prepdir/

# this comes from update_repos.sh + sitescripts.subscriptions.bin.updateSubscriptionDownloads
cp -a {{ filter_list_origin_outputs }}/data/* $prepdir/

# this comes from update_repos.sh + compress_files.sh
cp -a {{ filter_list_origin_outputs }}/gzip/* $prepdir/

# this comes from fetch_gitlab_artifacts.sh
cp -a {{ filter_list_origin_outputs }}/gitlab_artifacts/* $prepdir/

rm -rf $finaldir.old
test ! -d $finaldir || mv $finaldir $finaldir.old
# minimal race condition is here - this is where we don't want anyone reading from $finaldir
# but rsync --max-delete=anything on filter-servers protects us from downtime here
mv $prepdir $finaldir

# $finaldir is referenced from /etc/ssh/sshd_config ForceCommand
