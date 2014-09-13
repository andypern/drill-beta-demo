#!/usr/bin/bash

HBVERSION=$( cat /opt/mapr/hbase/hbaseversion )




export HBASE_HOME=/opt/mapr/hbase/hbase-${HBVERSION}
CLUSTERNAME=$( head -n 1 /opt/mapr/conf/mapr-clusters.conf|awk {'print $1'} )
NFSMOUNT=/mapr/${CLUSTERNAME}
TABLENAME="sustomers"
TABLEPATH=${NFSMOUNT}/tables/${TABLENAME}

#first delete table via hbase shell
echo 'disable '"'${TABLEPATH}'"'' | hbase shell

echo 'drop '"'${TABLEPATH}'"'' | hbase shell

#create table + 2 CF's
echo 'create '"'${TABLEPATH}'"',"personal","address","loyalty"' | hbase shell

#import

hadoop jar $HBASE_HOME/hbase-0.94.21-mapr-1407.jar \
        importtsv -Dimporttsv.separator=, \
        -Dimporttsv.columns=HBASE_ROW_KEY,personal:name,address:state,personal:gender,personal:age,loyalty:agg_rev,loyalty:membership\
        ${TABLEPATH} \
        /mapr/${CLUSTERNAME}/drill-beta-demo/data/output/customers.all.csv
