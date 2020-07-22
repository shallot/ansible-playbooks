#!/bin/sh -e
# TODO: integrate the logging into the script itself
# https://gitlab.com/eyeo/devops/legacy/sitescripts/-/issues/18
exec env PYTHONPATH=/opt/sitescripts \
  python -m sitescripts.subscriptions.bin.updateSubscriptionDownloads \
  3>&1 1>{{ filter_list_origin_logs }}/subscription_output 2>&3 \
  | perl -pe 's/^/"[" . scalar localtime() . "] "/e' \
  >> {{ filter_list_origin_logs }}/subscription_errors
