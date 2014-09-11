#!/usr/bin/bash

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )




export HBASE_HOME=/opt/mapr/hbase/hbase-${HBVERSION}
CLUSTERNAME=$( cat /opt/mapr/conf/mapr-clusters.conf |awk {'print $1'} )
TABLENAME="customers"

#first delete table via hbase shell
echo 'disable '"'${TABLENAME}'"'' | hbase shell

echo 'drop '"'${TABLENAME}'"'' | hbase shell

#create table + 2 CF's
echo 'create '"'${TABLENAME}'"',"personal","address","loyalty"' | hbase shell

#import

hadoop jar $HBASE_HOME/hbase-0.94.21-mapr-1407-SNAPSHOT.jar \
        importtsv -Dimporttsv.separator=, \
        -Dimporttsv.columns=HBASE_ROW_KEY,personal:name,address:state,personal:gender,personal:age,loyalty:agg_rev,loyalty:membership\
        ${TABLENAME} \
        /mapr/${CLUSTERNAME}/drill-beta-demo/data/output/customers.all.csv
