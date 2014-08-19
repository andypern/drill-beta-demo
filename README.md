#Drill demo on sandbox

##Intro


##Pre-reqs

* 3.1.1 sandbox (get from http://package.mapr.com/releases/v3.1.1/sandbox/)
* internet connectivity from sandbox to outside world


##Setup

To make life easier, we'll be using a github package to grab the dataset and to run some simple shell scripts to pull down drill and populate the data.


###Install packages

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

In the UI (http://ip:8047) , do the following:

click '


###Check sample queries




