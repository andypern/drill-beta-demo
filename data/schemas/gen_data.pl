#!/usr/bin/perl -w
use strict;
use File::Find;
use File::Copy;
use File::Basename;
use Cwd;
my $cwd = cwd();

my $linecount = 0;

my $logsynth = "/usr/bin/java -cp /Users/apernsteiner/git/log-synth/target/log-synth-0.1-SNAPSHOT-jar-with-dependencies.jar com.mapr.synth.Synth";


my $outdir = $cwd;
$outdir =~ s/schemas/output/;
my $orderdir = "$outdir/orders";
system("mkdir -p $outdir");
system("rm -rf $outdir/orders/*");

find(\&findsub, cwd);
find(\&findout, $orderdir);


print "$outdir\n";

sub findsub {
    if (/month[0-9]{1,2}.+orders.+json/) {
        my $shortname = $_;
        my $filename = $File::Find::name;
        orders_gen ($filename, $shortname);
	}

}

#now we need to post-process






sub orders_gen {
	my $schema_file = shift;
	my $outfile = shift;
	$outfile =~ s/json/csv/;
	$outfile = $orderdir . "/" . $outfile;
	#print "$outfile\n";
	#print "schema file : $schema_file\n";
	open(SCHEMA, $schema_file) or die "filename is bad, dying now..";
    my @schemadata = <SCHEMA>;
    close(SCHEMA);
    if($schemadata[0] =~ /count ([0-9]+)/){
    	my $count = $1;
    	#print "-count $count\n";
    	system("$logsynth -count $count -schema $schema_file > $outfile");
    	
    	

    }
}

sub findout {
	if (/month[0-9]{1,2}.+orders.+csv/) {
        my $shortname = $_;
        my $filename = $File::Find::name;
        orders_agg ($filename, $shortname);
	}
}

sub orders_agg {
	my $csvfile = shift;
	my $shortfile = shift;
	if ($shortfile =~ /month([0-9]{1,2})\.orders.+csv/) {
		#regular orders file
		my $month = $1;
		my $agg_file = "$outdir/orders/month$month.agg.orders.csv";
		unless(-e $agg_file){
			system("touch $agg_file");
		}
		my $iter = 0;
		open(INPUT, $csvfile) or die "filename is bad, dying now..";
	    my @data = <INPUT>;
	    close(INPUT);
	    open(OUTPUT, ">>$agg_file");
	    foreach my $line (@data) {
	    	unless($iter < 1){
	    		$line =~ s/"//g;
	    		# if($line =~ /([0-9]+,)"([A-Za-z]+)"(,)"([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+)"(,.+)/) {
	    		# 	my $newline = $1 . $2 . $3 . 4 . 5;
	    		# 	print OUTPUT "$newline\n";
	    		# }
	    		print OUTPUT $line;
	    	}
	    	$iter +=1;
	    }
	    close(OUTPUT);
	    #print "$csvfile had $iter lines\n";
	    $linecount += $iter;
	    unlink $csvfile;

	}elsif  ($shortfile =~ /month([0-9]{1,2})\.[a-z]{2}\.orders.+csv/) {
		#state specific file, nothing special to do here
		my $month = $1;
		my $agg_file = "$outdir/orders/month$month.agg.orders.csv";
		unless(-e $agg_file){
			system("touch $agg_file");
		}
		my $iter = 0;
		open(INPUT, $csvfile) or die "filename is bad, dying now..";
	    my @data = <INPUT>;
	    close(INPUT);
	    open(OUTPUT, ">>$agg_file");
	    foreach my $line (@data) {
	    	unless($iter < 1){
	    		$line =~ s/"//g;
	    		print OUTPUT $line;
	    # 		if($line =~ /([0-9]+,)"([A-Za-z]+)"(,)"([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+)"(,.+)/) {
					# my $newline = $1 . $2 . $3 . $4 . $5;
					# print OUTPUT "$newline\n";
	    # 		}
	    	}
	    	$iter +=1;
	    }
	    close(OUTPUT);
	    #print "$csvfile had $iter lines\n";
	    $linecount += $iter;
	    unlink $csvfile;
	}elsif  ($shortfile =~ /month([0-9]{1,2})\.allstates\.orders.+csv/) {
		# allstates files..we have to strip out the state specific stuff.
		my $month = $1;
		my $agg_file = "$outdir/orders/month$month.agg.orders.csv";
		unless(-e $agg_file){
			system("touch $agg_file");
		}
		my $iter = 0;
		open(INPUT, $csvfile) or die "filename is bad, dying now..";
	    my @data = <INPUT>;
	    close(INPUT);
	    open(OUTPUT, ">>$agg_file");
	    foreach my $line (@data) {
	    	#chomp($line);
	    	unless($iter < 1){
	    		unless($line =~ /"ca"|"il"/){
		    		$line =~ s/"//g;
		    		print OUTPUT $line;
		    # 		if($line =~ /([0-9]+,)"([A-Za-z]+)"(,)"([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]+)"(,.+)/) {
						# my $newline = $1 . $2 . $3 . $4 . $5;
						# print OUTPUT "$newline\n";
	    	# 		}
		    	}
	    	}
	    	$iter +=1;
	    }
	    close(OUTPUT);
	    #print "$csvfile had $iter lines\n";
	    $linecount += $iter;
	    unlink $csvfile;

	}

}

print "$linecount lines\n";
