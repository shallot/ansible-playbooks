
# https://www.gnu.org/software/make/manual/html_node/Environment.html
# for audit-log-to-ping-csv-with-country
export PATH := $(PATH):/usr/local/bin

# https://www.gnu.org/software/make/manual/html_node/Shell-Function.html
# we get yesterday's date from the environment, but also need the day before
# for later
DAY_BEFORE_DATE ?= $(shell date -d "$(DATE) - 1 day" "+%Y-%m-%d")

# TODO - stop deducing this and move to outside environment like all the above
# this implies all input servers are named foo-bar-<N>.example.com
SERVER_SHORTNAME ?= $(firstword $(subst ., ,$(SERVER)))
PRODUCT_DATASTORE_SERVER_ID ?= $(lastword $(subst -, , $(SERVER_SHORTNAME)))

# /etc/logrotate.d/local-telemetry-pingv1-apache will run at midnight, and
# the rotated file with this date suffix will exist
SERVER_LOG_SUFFIX ?= $(DATE)
# this needs to match group_vars/telemetry-pingv1-servers.yml
# telemetry-pingv1_apache2_sites__to_merge
# logrotate-telemetry-pingv1_custom_paths__to_merge
SERVER_LOG_PREFIX ?= $(PRODUCT)-post-raw

SERVER_LOG_LOCATION ?= $(SERVER_LOG_DIRECTORY)/$(SERVER_LOG_PREFIX).log.$(SERVER_LOG_SUFFIX)

# this is a simple trick to be able to do debugging by running e.g.
# make DO=@echo
DO ?= 

.PHONY: all
all: sanity_check download rawcsv dailycsv upload

sanity_check:
ifndef SERVER
	$(error SERVER variable is undefined)
endif
#ifndef PRODUCT_DATASTORE_SERVER_ID
#	$(error PRODUCT_DATASTORE_SERVER_ID variable is undefined)
#endif

# download target is for fetching log files from the servers that
# process traffic
.PHONY: download
download: \
	$(PRODUCT_DIRECTORY)/downloaded/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz

# https://www.gnu.org/software/make/manual/html_node/Target_002dspecific.html
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
$(PRODUCT_DIRECTORY)/downloaded/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz: \
	PLAINNAME = $(subst .gz,,$@)
$(PRODUCT_DIRECTORY)/downloaded/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz:
	@test -d $(@D) || install -v -d $(@D)
	$(DO) rsync -av '$(SERVER):$(SERVER_LOG_LOCATION)' '$(PLAINNAME)'
# by default, the log suffix will not contain .gz because logrotate
# will not compress yesterday's log file
ifeq "$(findstring .gz,$(SERVER_LOG_SUFFIX))" ""
	$(DO) gzip -f $(PLAINNAME) # -> $@
else
# when we need to recover something from the day before yesterday,
# the remote file will have been gzipped already by logrotate
	$(DO) mv $(PLAINNAME) $@
endif

# rawcsv target is for generating CSV files from the log files using
# our custom parser utility
.PHONY: rawcsv
rawcsv: \
	$(PRODUCT_DIRECTORY)/rawcsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz

$(PRODUCT_DIRECTORY)/rawcsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz: \
		$(PRODUCT_DIRECTORY)/downloaded/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz
	@test -d $(@D) || install -v -d $(@D)
# files/telemetry-log-fetch/audit-log-to-ping-csv-with-country
	$(DO) sh -xc "zcat $< | audit-log-to-ping-csv-with-country | gzip > $@"

# dailycsv target is for making CSV files contain exactly the days they're
# named after
.PHONY: dailycsv
dailycsv: \
	$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz

$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz: \
		$(PRODUCT_DIRECTORY)/rawcsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz
	@test -d $(@D) || install -v -d $(@D)
# there is always a bit of overlap between dates in log files, as logrotate does not
# cut off exactly at midnight, but we want the destination files to be cut that way
# NB: the zgrep of the file from the day before yesterday means we can't just use
# implicit rules per https://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
# but always have to keep today's raw CSV files for reuse tomorrow
	$(DO) zgrep -a -h '^$(DATE)' $(<D)/$(SERVER_LOG_PREFIX).log.$(DAY_BEFORE_DATE).gz $< | gzip > $@

# upload target is uploading the daily CSV files into Google Cloud Storage
# and then from there ingesting them into Google BigQuery
.PHONY: upload
upload: \
	uploaded_$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz

.PHONY: uploaded_$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
uploaded_$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz: \
	TARGET = "$(PRODUCT_DATASTORE_BUCKET)/$(DATE)-$(SERVER_SHORTNAME).gz"
# https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv#loading_csv_data_into_a_new_table
# https://cloud.google.com/bigquery/docs/managing-partitioned-tables
# NB: $ is the BigQuery partition decorator separator, but has to be escaped in make to get to shell,
# and then in shell to get to the bq command itself
# these partitions are meant to be daily
uploaded_$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz: \
		$(PRODUCT_DIRECTORY)/dailycsv/$(SERVER)/$(SERVER_LOG_PREFIX).log.$(DATE).gz
	$(DO) gsutil -q cp "$<" "$(TARGET)"
	$(DO) bq load --source_format="CSV" --max_bad_records=$(PRODUCT_DATASTORE_MAX_BAD_RECORDS) --time_partitioning_type DAY --replace "$(PRODUCT_DATASTORE_PREFIX)_$(PRODUCT_DATASTORE_SERVER_ID)\$$$(PRODUCT_DATASTORE_SUFFIX)" "$(TARGET)" "$(PRODUCT_DATASTORE_SCHEMA)"
