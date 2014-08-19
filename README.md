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


####HBASE

	{
	  "type" : "hbase",
	  "enabled" : true,
	  "config" : {
	    "hbase.zookeeper.quorum" : "localhost",
	    "hbase.zookeeper.property.clientPort" : "5181"
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




