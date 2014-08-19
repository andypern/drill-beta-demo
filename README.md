#Drill demo on sandbox

##Intro


##Pre-reqs

* 3.1.1 sandbox (get from http://package.mapr.com/releases/v3.1.1/sandbox/)
* internet connectivity from sandbox to outside world


##Setup

To make life easier, we'll be using a github package to grab the dataset and to run some simple shell scripts to pull down drill and populate the data.


###Install packages

To start, ssh as root to your sandbox VM.

Install git:

	yum install -y git

Go to proper directory:

	cd /mapr/demo.mapr.com


Grab repo:

	git clone https://github.com/andypern/drill-beta-demo

Go to proper directory:

	cd drill-beta-demo

Run setup script:

	sh scripts/setup.sh

	
	


###configure storage-plugins

In the UI (http://ip:8047) , go to the Storage page, then create the following storage-plugins:



####MapRDB

	
	{
	  "type" : "hbase",
	  "enabled" : true,
	  "config" : {
	    "hbase.table.namespace.mappings" : "*:/tables"
	  }
	}


	
	
####MFS

	{
	  "type": "file",
	  "enabled": true,
	  "connection": "maprfs:///",
	  "workspaces": {
	    "root": {
	      "location": "/mapr/demo.mapr.com/data",
	      "writable": false,
	      "storageformat": null
	    },
	    "nested": {
	      "location": "/mapr/demo.mapr.com/data/clicks",
	      "writable": true,
	      "storageformat": "parquet"
	    },
	    "flat": {
	      "location": "/mapr/drilldemo/data/logs",
	      "writable": true,
	      "storageformat": "parquet"
	    },
	    "views": {
	      "location": "/mapr/drilldemo/data/views",
	      "writable": true,
	      "storageformat": "parquet"
	    }
	  },
	  "formats": {
	    "psv": {
	      "type": "text",
	      "extensions": [
	        "tbl"
	      ],
	      "delimiter": "|"
	    },
	    "csv": {
	      "type": "text",
	      "extensions": [
	        "csv"
	      ],
	      "delimiter": ","
	    },
	    "tsv": {
	      "type": "text",
	      "extensions": [
	        "tsv"
	      ],
	      "delimiter": "\t"
	    },
	    "parquet": {
	      "type": "parquet"
	    },
	    "json": {
	      "type": "json"
	    }
	  }
	}
	
####HIVE

	{
	  "type": "hive",
	  "enabled": true,
	  "configProps": {
	    "hive.metastore.uris": "thrift://localhost:9083",
	    "hive.metastore.sasl.enabled": "false"
	  }
	}
	

###Check sample queries


The setup.sh script creates an alias, to make it easier to launch sqlline.  to verify if your queries are working:

	sqlline

At the sqlline prompt:

	0: jdbc:drill:> show databases;

You should see something like this:

	+-------------+
	| SCHEMA_NAME |
	+-------------+
	| hive.default |
	| hbase       |
	| sys         |
	| MFS.default |
	| MFS.nested  |
	| MFS.root    |
	| MFS.views   |
	| MFS.flat    |
	| INFORMATION_SCHEMA |
	| MAPRDB      |
	+-------------+

Switch to hive.default workspace:

	0: jdbc:drill:> use hive.`default`;

Verify tables exist:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| hive.default | orders     |
	| hive.default | customers  |
	+--------------+------------+
	2 rows selected (1.157 seconds)

Quick selects:

	select * from orders limit 10;
	select * from customers limit 10;


Now for MaRDB:
	
	0: jdbc:drill:> use maprdb;

Verify tables exist:

	0: jdbc:drill:> show tables;
	+--------------+------------+
	| TABLE_SCHEMA | TABLE_NAME |
	+--------------+------------+
	| hbase        | products   |
	+--------------+------------+
	1 row selected (0.437 seconds)
	
	

