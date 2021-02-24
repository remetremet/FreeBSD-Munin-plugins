#!/usr/local/bin/perl -w
# -*- cperl -*-

=head1 NAME

dhcpd - Plugin to monitor dhcpd leases

=head1 APPLICABLE SYSTEMS

Any system running dhcpd.

This plugins requires these Perl modules to work: Net::Netmask and
HTTP::Date.


=head1 CONFIGURATION

The following environment settings are the default configuration.  The
"user" setting is needed and must be set explicitly.

  [dhcpd]
     user root
     env.leasefile /var/lib/dhcp3/dhcpd.leases
     env.configfile /etc/dhcp3/dhcpd.conf
     env.filter  ^10\.140\.
     env.critical 0.95
     env.warning 0.9

The optional filter setting is used to strip parts of ranges for the 
network labels (example will show 10.140.80.0 as 80.0). Both critical
and warning are optional settings, default for warning is 0.9 (90%) 
and 0.95 for critical (95%).

=head1 INTERPRETATION

The plugin shows the number of used leases by subnet.

=head1 MAGIC MARKERS

  #%# family=contrib
  #%# capabilities=autoconf

=head1 VERSION

  $Id$

=head1 BUGS

If a DHCP config file contains multiple subnets but none of them has a
dynamic range, the dhcp3 plugin only detects this situation for the
last subnet.  Need to to improve the parser to properly detect the end
of a subnet definition (Munin trac ticket #829)

=head1 AUTHOR

Rune Nordbøe Skillingstad.

=head1 LICENSE

GPLv2

=cut


my $ret = undef;

if(! eval "require Net::Netmask") {
    $ret = "Net::Netmask not found";
}
if(! eval "require HTTP::Date") {
    $ret = "HTTP::Date not found";
}
if(! eval "require Net::IP") {
    $ret = "Net::IP not found";
}	  


use strict;

my %leases     = ();
my %limits     = ();
my %networks   = ();
my %networks6   = ();
my %ips        = ();
my $DEBUG      = $ENV{DEBUG}      || 0;

my $LEASEFILE  = $ENV{leasefile}  || "/var/db/dhcpd/dhcpd.leases";
my $LEASE6FILE  = $ENV{lease6file}  || "/var/db/dhcpd6/dhcpd6.leases";
my $CONFIGFILE = $ENV{configfile} || "/etc/dhcpd.conf";
my $CONFIG6FILE = $ENV{config6file} || "/etc/dhcpd6.conf";
my $FILTER     = $ENV{filter}     || "";
my $CRITICAL   = $ENV{critical}   || 0.95;
my $WARNING    = $ENV{warning}    || 0.9;

if($ARGV[0] and $ARGV[0] eq "autoconf" ) {
    if($ret) {
	print "no ($ret)\n";
	exit 0;
    }
    if(-f $LEASEFILE) {
	if(-r $LEASEFILE) {
	    if(-f $CONFIGFILE) {
		if(-r $CONFIGFILE) {
		    print "yes\n";
		    exit 0;
		} else {
		    print "no (config file not readable)\n";
		}
	    } else {
		print "no (config file not found)\n";
	    }
	} else {
	    print "no (leasefile not readable)\n";
	}
    } else {
	print "no (leasefile not found)\n";
    }
    exit 0;
}

print "# DEBUG: CONFIGFILE == $CONFIGFILE\n# DEBUG: LEASEFILE == $LEASEFILE\n" if $DEBUG;
print "# DEBUG: CONFIG6FILE == $CONFIG6FILE\n# DEBUG: LEASE6FILE == $LEASE6FILE\n" if $DEBUG;

Net::Netmask->import();
HTTP::Date->import();

if(! -f $LEASEFILE and ! -f $CONFIGFILE and !$ARGV[0]) {
    print "net.value U\n";
    exit 0;
}

parseconfig($CONFIGFILE);
parseconfig6($CONFIG6FILE);

if($ARGV[0] and $ARGV[0] eq "config") {
    print "graph_title dhcp leases\n";
    print "graph_args --base 1000 -v leases -l 0\n";
    print "graph_category network\n";
    print "graph_order ".join(" ",sort(keys(%leases)))."\n";
    foreach my $network (sort(keys %leases)) {
	my $name = $network;
	$name =~ s/_/\./g;
	$name =~ s/\.\./\//g;
	print "$network.info $name\n";
	$name =~ s/($FILTER)//;
	print "$network.label $name\n";
	print "$network.min 0\n";
        if ($limits{$network} > 0) {
	 print "$network.max " . $limits{$network} ."\n";
	 if ($limits{$network} > 255) {
 	    my $warn = int(255 * 0.9);
 	    my $crit = int(255 * 0.95);
 	    print "$network.warning $warn\n" if $warn;
 	    print "$network.critical $crit\n" if $crit;
         } else {
	    if ($limits{$network} > 0) {
		my $warn = int($limits{$network} * 0.9);
		my $crit = int($limits{$network} * 0.95);
 	   	print "$network.warning $warn\n" if $warn;
 	   	print "$network.critical $crit\n" if $crit;
 	    }
         }
        }
    }
    exit 0;
}

parseleases();
parseleases6();

foreach my $network (sort(keys %leases)) {
    print "$network.value ".$leases{$network}."\n";
}

sub parseconfig {
    my($configfile) = @_;
    
    local(*IN);
    open(IN, "<$configfile") or exit 4;
    
    my $name = undef;
    LINE: while(<IN>) {
	if(/subnet\s+((?:\d+\.){3}\d+)\s+netmask\s+((?:\d+\.){3}\d+)/ && ! /^\s*#/) {
	    $name = &initnet($1,$2);
	    print "# DEBUG: Found a subnet: $name\n" if $DEBUG;
	}
	if($name && /^\}$/) {
            if(!exists $limits{$name}) {
                print "# DEBUG: End of subnet... NO RANGE?\n" if $DEBUG;
                delete($leases{$name});
            }
	    $name = "";
	}
	if($name && /range\s+((?:\d+\.){3}\d+)\s+((?:\d+\.){3}\d+)/) {
	    print "# DEBUG: range $1 -> $2\n" if $DEBUG;
	    $limits{$name} += &rangecount($1, $2);
	    print "# DEBUG: limit for $name is " . $limits{$name} . "\n" if $DEBUG;
	}
	if(/^include \"([^\"]+)\";/) {
	    my $includefile = $1;
	    print "# DEBUG: found included file: $includefile\n" if $DEBUG;
	    if(!-f $includefile) {
		$includefile = dirname($CONFIGFILE) . "/" . $includefile;
		if(!-f $includefile) {
		    next LINE;
		}
	    }
	    parseconfig($includefile);
	}
    }
    close(IN);
}

sub parseconfig6 {
    my($configfile) = @_;
    
    local(*IN);

    open(IN, "<$configfile") or exit 4;
    
    my $name6 = undef;
    LINE: while(<IN>) {
	if(/subnet6\s+(\w{1,4}(:{1,2}\w{0,4}){1,7})\/(\d{2})/ && ! /^\s*#/) {
	    $name6 = &initnet6($1,$3);
	    print "# DEBUG: Found a subnet6: $name6\n" if $DEBUG;
	}
	if($name6 && /^\}$/) {
            if(!exists $limits{$name6}) {
                print "# DEBUG: End of subnet... NO RANGE?\n" if $DEBUG;
                delete($leases{$name6});
            }
	    $name6 = "";
	}
	if($name6 && /range6\s+(\w{1,4}(:{1,2}\w{0,4}){1,7})\s+(\w{1,4}(:{1,2}\w{0,4}){1,7})/) {
	    print "# DEBUG: range6 $1 -> $3\n" if $DEBUG;
	    $limits{$name6} += &rangecount6($1, $3);
	    print "# DEBUG: limit for $name6 is " . $limits{$name6} . "\n" if $DEBUG;
	}
	if(/^include \"([^\"]+)\";/) {
	    my $includefile = $1;
	    print "# DEBUG: found included file: $includefile\n" if $DEBUG;
	    if(!-f $includefile) {
		$includefile = dirname($CONFIG6FILE) . "/" . $includefile;
		if(!-f $includefile) {
		    next LINE;
		}
	    }
	    parseconfig($includefile);
	}
    }
    close(IN);
}

sub rangecount {
    my ($from, $to) = @_;

    $from = ((new Net::IP($from))->intip())->numify();
    $to   = ((new Net::IP($to))->intip())->numify();
    
    if($from < $to) {
	return ($to - $from) + 1;
    } else {
	return ($from - $to) + 1;
    }
}

sub rangecount6 {
    my ($from, $to) = @_;

    $from=Net::IP::ip_expand_address($from,6);
    $to=Net::IP::ip_expand_address($to,6);
    my $binfrom=Net::IP::ip_iptobin($from,6);
    my $binto=Net::IP::ip_iptobin($to,6);
    my $intfrom=Net::IP::ip_bintoint($binfrom,6);
    my $intto=Net::IP::ip_bintoint($binto,6);
    my $ip_count=0;
    if($intfrom < $intto) {
        $ip_count=($intto - $intfrom) + 1;
    } else {
	$ip_count=($intfrom - $intto) + 1;
    }
    return $ip_count;
}

sub parseleases {
    my $ip = 0;
    my $abandon = 0;
    my $time    = time(); 

    open(IN, "<$LEASEFILE") or exit 4;
    while(<IN>) {
	if(/lease\s+(\d+\.\d+\.\d+\.\d+)\s+\{/) {
	    print "# DEBUG: in $1\n" if $DEBUG;
	    $ip = $1;
	}
	if($ip && /ends\s+\d+\s+([^;]+);/) {
            # 2037/12/31 23:59:59 is max date on perl <= 5.6
	    print "# DEBUG: end $1\n" if $DEBUG;
	    my $end = HTTP::Date::str2time($1, "GMT");
	    # we asume that missing $end is valid due to 
	    # restrictions in Time::Local on perl <= 5.6
	    if($end && $end < $time) { 
		print "# DEBUG: old $end $time:(\n" if $DEBUG;
		$abandon = 1;
	    }
	}
	if($ip && /^\s*abandoned;$/) {
	    print "# DEBUG: abandoned\n" if $DEBUG;
	    $abandon = 1;
	}
	if($ip && /^\s*\}\s*$/) {
	    my $net = checkip($ip);
	    if($net && !$abandon) {
		if(!counted($ip)) {
			$leases{$net}++;
		}
	    }
	    $abandon = 0;
	    $ip      = 0;
	    print "# DEBUG: out\n" if $DEBUG;
	}
    }
    close(IN);

}

sub parseleases6 {
    my $ip = 0;
    my $abandon = 0;
    my $time    = time(); 

    open(IN, "<$LEASE6FILE") or exit 4;
    while(<IN>) {
        if(/iaaddr\s+(\w{1,4}(:{1,2}\w{0,4}){1,7})\s+\{/) {
	    print "# DEBUG: in $1\n" if $DEBUG;
	    $ip = $1;
	}
	if($ip && /ends\s+\d+\s+([^;]+);/) {
            # 2037/12/31 23:59:59 is max date on perl <= 5.6
	    print "# DEBUG: end $1\n" if $DEBUG;
	    my $end = HTTP::Date::str2time($1, "GMT");
	    # we asume that missing $end is valid due to 
	    # restrictions in Time::Local on perl <= 5.6
	    if($end && $end < $time) { 
		print "# DEBUG: old $end $time:(\n" if $DEBUG;
		$abandon = 1;
	    }
	}
	if($ip && /^\s*abandoned;$/) {
	    print "# DEBUG: abandoned\n" if $DEBUG;
	    $abandon = 1;
	}
	if($ip && /^\s*\}\s*$/) {
	    my $net = checkip6($ip);
	    if($net && !$abandon) {
		if(!counted($ip)) {
			$leases{$net}++;
		}
	    }
	    $abandon = 0;
	    $ip      = 0;
	    print "# DEBUG: out\n" if $DEBUG;
	}
    }
    close(IN);
}

sub initnet {
    my ($net, $mask) = @_;
    my $block = new Net::Netmask($net, $mask);
    $networks{$block->desc()} = $block;
    my $name = $block->desc();
    $name =~ s/\//__/g;
    $name =~ s/\./_/g;
    $leases{$name} = 0;
    $limits{$name} = 0;
    return $name;
}

sub initnet6 {
    my ($net,$prefix) = @_;
    my $block = $net . "/" . $prefix;
    $net =~ s/^(\w{1,4}(:\w{0,4}){1,3}).*/$1/g;
    $networks6{$block}=$net;
    my $name = $block;
    $name =~ s/::\//__/g;
    $name =~ s/\//__/g;
    $name =~ s/:/_/g;
    $leases{$name} = 0;
    $limits{$name} = 0;
    return $name;
}

sub checkip {
    my ($ip) = @_;
    foreach my $block (keys %networks) {
	if($networks{$block}->match($ip)) {
	    my $name = $block;
	    $name =~ s/\//__/g;
	    $name =~ s/\./_/g;
	    return $name;
	}
    }
    return 0;
}

sub checkip6 {
    my ($ip) = @_;
    foreach my $block (keys %networks6) {
        my $ipnet=$ip;
        $ipnet =~ s/^(\w{1,4}(:\w{0,4}){1,3}).*/$1/g;
	if( $networks6{$block} eq $ipnet ) {
	    my $name = $block;
            $name =~ s/::\//__/g;
	    $name =~ s/\//__/g;
	    $name =~ s/:/_/g;
	    return $name;
	}
    }
    return 0;
}

sub counted {
    my ($ip) = @_;
    if($ips{$ip}) {
	print "# DEBUG: $ip already counted\n" if $DEBUG;
	return 1;
    }
    $ips{$ip} = $ip;
    print "# DEBUG: Counted $ip once!\n" if $DEBUG;
    return 0;
}

exit();
