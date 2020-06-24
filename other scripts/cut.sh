#!/bin/bash
date_time=$(date -d yesterday +%Y%m%d)
slow_log='/data/mysql/3308/slowlog.log'
slow_log_prefix=$(dirname $slow_log)
cp ${slow_log}  ${slow_log_prefix}/slow_$date_time.log
gzip ${slow_log_prefix}/slow_$date_time.log
chown mysql.mysql ${slow_log_prefix}/slow_$date_time.log.gz
>$slow_log
