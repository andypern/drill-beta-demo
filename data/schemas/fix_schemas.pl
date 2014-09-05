#!/usr/bin/perl -w
use strict;
use File::Find;
use File::Copy;
use File::Basename;
use Cwd;
my $cwd = cwd();

my $iter = 0;
my $tempdir = "$cwd/temp";
system("rm -rf $tempdir/*");
system("mkdir -p $tempdir");
my $jsondir = "$cwd/orders";

find(\&findsub, $jsondir);




sub findsub {
    if (/month[0-9]{1,2}.+orders.+json/) {
        my $shortname = $_;
        my $filename = $File::Find::name;
       	open(INPUT, $filename) or die "filename is bad, dying now..";
	    my @data = <INPUT>;
	    close(INPUT);
	    open(OUTPUT, ">>$tempdir/$shortname");
	    foreach my $line (@data) {
	    	if($line =~ /({"name":"date", "class":"date", "format":"yyyy-MM-dd)(", "start":"[0-9]{4}-[0-9]{2}-[0-9]{2})(", "end":"[0-9]{4}-[0-9]{2}-[0-9]{2})"},/){
	    		my $newline = $1 . " HH:mm:ss" . $2 . " 00:00:01" . $3 . " 23:59:59\"},";
	    		print OUTPUT "$newline\n";
	    		print "$newline\n";
	    		$iter += 1;
	    	}else{
	    		print OUTPUT $line;	
	    	}
	    }
	    close(OUTPUT);
	}

}

print "made $iter changes\n";