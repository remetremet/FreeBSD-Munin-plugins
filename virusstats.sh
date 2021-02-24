#!/usr/local/bin/perl
# -*- perl -*-

=head1 NAME

spamstats - Plugin to graph spamassassin throughput

=head1 CONFIGURATION

This plugin does not have any configuration

=head1 AUTHOR

Unknown author

=head1 LICENSE

GPLv2

=head1 MAGIC MARKERS

 #%# family=contrib

=cut


$statefile = $ENV{statefile} || "$ENV{MUNIN_PLUGSTATE}/munin-virusstats.state";
$pos   = undef;
$cln = 0;
$inf = 0;

$logfile = $ENV{logdir} || "/var/log/";
$logfile .= $ENV{logfile} || "maillog";

if (-f "$logfile.0")
{
    $rotlogfile = $logfile . ".0";
}
elsif (-f "$logfile.1")
{
    $rotlogfile = $logfile . ".1";
}
elsif (-f "$logfile.01")
{
    $rotlogfile = $logfile . ".01";
}
else
{
    $rotlogfile = $logfile . ".0";
}

if ( $ARGV[0] and $ARGV[0] eq "config" )
{
    print "host_name $ENV{FQDN}\n";
    print "graph_title AntiVirus throughput\n";
    print "graph_args --base 1000 -l 0\n";
    print "graph_vlabel mails/\${graph_period}\n";
    print "graph_category mail\n";
    print "graph_order cln inf\n";
    print "cln.label clean\n";
    print "cln.type DERIVE\n";
    print "cln.min 0\n";
    print "cln.draw AREA\n";
    print "inf.label infected\n";
    print "inf.type DERIVE\n";
    print "inf.min 0\n";
    print "inf.draw STACK\n";
    exit 0;
}

if (! -f $logfile and ! -f $rotlogfile)
{
    print "cln.value U\n";
    print "inf.value U\n";
    exit 0;
}

if (-f "$statefile")
{
    open (IN, "$statefile") or exit 4;
    if (<IN> =~ /^(\d+):(\d+):(\d+)/)
    {
	($pos, $cln, $inf) = ($1, $2, $3);
    }
    close IN;
}

$startsize = (stat $logfile)[7];

if (!defined $pos)
{
    # Initial run.
    $pos = $startsize;
}

if ($startsize < $pos)
{
    # Log rotated
    if (-f $rotlogfile) {
        parselogfile ($rotlogfile, $pos, (stat $rotlogfile)[7]);
    }
    $pos = 0;
}

parselogfile ($logfile, $pos, $startsize);
$pos = $startsize;

print "cln.value $cln\n";
print "inf.value $inf\n";

open (OUT, ">$statefile") or exit 4;
print OUT "$pos:$cln:$inf\n";
close OUT;

sub parselogfile 
{    
    my ($fname, $start, $stop) = @_;
    open (LOGFILE, $fname) or exit 3;
    seek (LOGFILE, $start, 0) or exit 2;

    while (tell (LOGFILE) < $stop) 
    {
	my $line =<LOGFILE>;
	chomp ($line);

	if ($line =~ m/Clean/) 
	{
	    $cln++;
	} 
	elsif ($line =~ m/Infected/)
	{
	    $inf++;
	}
    }
    close(LOGFILE);    
}
