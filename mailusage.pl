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


$statefile = $ENV{statefile} || "$ENV{MUNIN_PLUGSTATE}/munin-mailusage.state";
$pos   = undef;
$pop = 0;
$imap = 0;
$smtp = 0;

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
    print "graph_title Mail server usage statistics\n";
    print "graph_args --base 1000 -l 0\n";
    print "graph_vlabel calls/\${graph_period}\n";
    print "graph_category mail\n";
    print "graph_order pop imap smtp\n";
    print "pop.label POP3\n";
    print "pop.type DERIVE\n";
    print "pop.min 0\n";
    print "pop.draw AREA\n";
    print "imap.label IMAP4\n";
    print "imap.type DERIVE\n";
    print "imap.min 0\n";
    print "imap.draw STACK\n";
    print "smtp.label SMTP\n";
    print "smtp.type DERIVE\n";
    print "smtp.min 0\n";
    print "smtp.draw STACK\n";
    exit 0;
}

if (! -f $logfile and ! -f $rotlogfile)
{
    print "pop.value U\n";
    print "imap.value U\n";
    print "smtp.value U\n";
    exit 0;
}

if (-f "$statefile")
{
    open (IN, "$statefile") or exit 4;
    if (<IN> =~ /^(\d+):(\d+):(\d+):(\d+)/)
    {
	($pos, $pop, $imap, $smtp) = ($1, $2, $3, $4);
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

print "pop.value $pop\n";
print "imap.value $imap\n";
print "smtp.value $smtp\n";

open (OUT, ">$statefile") or exit 4;
print OUT "$pos:$pop:$imap:$smtp\n";
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

	if ($line =~ m/ipop3d/) 
	{
          if ($line =~ m/Login user/)
          {
	    $pop++;
          }
	} 
	elsif ($line =~ m/imapd/)
	{
          if ($line =~ m/Authenticated user/)
          {
            $imap++;
          }
	}
	elsif ($line =~ m/sm-mta/)
	{
          if ($line =~ m/daemon=MTA/)
          {
            $smtp++;
          }
	}
    }
    close(LOGFILE);    
}
