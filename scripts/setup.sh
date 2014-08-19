#!/usr/bin/bash

#first, check that this is a sandbox



MYHOSTNAME=$( cat /opt/mapr/hostname )

if [[ $MYHOSTNAME == maprdemo ]]
	then
	echo "we are on a sandbox, continuing"
	else
	echo "not a sandbox, exiting"
	exit 1
fi

CLUSTERNAME=$( head -n 1 /opt/mapr/conf/mapr-clusters.conf|awk {'print $1'} )

NFSMOUNT=/mapr/${CLUSTERNAME}

#check that loopback mount works

if [ -d ${NFSMOUNT}/tables ]
	then "echo tables dir exists in $NFSMOUNT , continuing"
else
	echo "tables dir not in $NFSMOUNT , exiting"
	exit 1
fi


# grab tarball from package.mapr.com
cd /tmp
rm -f *.rpm
wget http://package.mapr.com/labs/drill/redhat/mapr-drill-0.4.0.26711-1.noarch.rpm


# install

rpm -ivh /tmp/mapr-drill-0.4.0.26711-1.noarch.rpm



#modify max memory and max heap in drill-env.sh

sed -r -i 's/8G/2G/' /opt/mapr/drill/drill-0.4.0/conf/drill-env.sh
sed -r -i 's/4G/1G/' /opt/mapr/drill/drill-0.4.0/conf/drill-env.sh

#fix zk port
sed -r -i 's/2181/5181/' /opt/mapr/drill/drill-0.4.0/conf/drill-override.conf 

#set hadoop_home

echo "export HADOOP_HOME="/opt/mapr/hadoop/hadoop-0.20.2/"" >> /opt/mapr/drill/drill-0.4.0/conf/drill-env.sh

# start drill
/opt/mapr/server/configure.sh -R


sleep 10

echo "restarting drillbits"
maprcli node services -name drill-bits -action restart -filter csvc==drill-bits



#verify ports are open:
echo "sleeping for 30 seconds"


sleep 30

lsof -i:8047

lsof -i:31010

# now, copy the datasets into place

REPODIR=${NFSMOUNT}/drill-beta-demo
DATADIR=${NFSMOUNT}/data

mkdir -p ${DATADIR}

cp -R ${REPODIR}/data/output ${DATADIR}


#make the HBASE table

sh ${REPODIR}/scripts/hbase.products.sh

#make the products table in MapRDB as well


sh ${REPODIR}/scripts/maprdb.products.sh


#make the HIVE tables

#first drop them

/usr/bin/hive -e "drop table customers;"

/usr/bin/hive -e "drop table orders;"


/usr/bin/hive -f ${REPODIR}/scripts/customers.hive.table.hql

/usr/bin/hive -f ${REPODIR}/scripts/orders.hive.hql



# at this point, everything is done.

echo "go to IP:8047 and setup your storage plugins"



