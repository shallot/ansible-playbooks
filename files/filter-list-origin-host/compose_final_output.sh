#!/bin/sh -e

prepdir={{ filter_list_origin_final_output }}_prep
finaldir={{ filter_list_origin_final_output }}
olddir={{ filter_list_origin_final_output }}_old

link_globs=$@

rm -rf $prepdir
mkdir $prepdir

# this comes from fetch_gitlab_artifacts.sh
cp -a {{ filter_list_origin_outputs }}/gitlab_artifacts/. $prepdir/

# this comes from fetch_gstorage_artifacts.sh
cp -a {{ filter_list_origin_outputs }}/gstorage_artifacts/. $prepdir/

# this replaces regular files with links to subdir files, if they exist
{{ filter_list_origin_base_dir }}/compound_webroot_structure.sh $prepdir "$link_globs"

# clean up olddir, if it exists
rm -rf $olddir

test ! -d $finaldir || mv $finaldir $olddir
# minimal race condition is here - this is where we don't want anyone reading from $finaldir
# but rsync --max-delete=anything on filter-servers protects us from downtime here
mv $prepdir $finaldir

# $finaldir is referenced from ssh forced command

test -d $olddir && tar --remove-files -vcf \
   {{ filter_list_origin_archive }}/final_output_old.tar $olddir 2>&1

# Delete old versions of final_output
/usr/sbin/logrotate -f -s {{ filter_list_origin_archive }}/status \
    {{ filter_list_origin_base_dir }}/rotate-final-output
