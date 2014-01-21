#!/usr/bin/env perl

use warnings;
use strict;

use Net::LDAPS;
use Net::LDAP::Control::Paged;
use Net::LDAP::Constant qw( LDAP_CONTROL_PAGED );

use DBI;

my $my_cnf = '/secret/my_cnf.cnf';

my $dbh = DBI->connect("DBI:mysql:"
	. ";mysql_read_default_file=$my_cnf"
	.';mysql_read_default_group=ldap',
	undef,
	undef
) or die "something went wrong ($DBI::errstr)";


my $clear_data = $dbh->prepare("truncate table ldap");
$clear_data->execute;

my $query = $dbh->prepare("insert into ldap (dn,title,department,description) values (?,?,?,?)");




my %config = do '/secret/actian.config';

my($ldap) = Net::LDAPS->new($config{'host'}) or die "Can't bind to ldap: $!\n";

$ldap->bind(
	dn  => "$config{'username'}",
	password => "$config{'password'}",
);  

my $page = Net::LDAP::Control::Paged->new( size => 100 );

my @args = ( 
	base     => $config{'base'},
	scope    => "subtree",
	filter   => "(objectClass=user)",
#	callback => \&process_entry, # Call this sub for each entry
	control  => [ $page ],
);

my $cookie;


while (1) {
	# Perform search
	my $mesg = $ldap->search( @args );

	die "LDAP error: server says ",$mesg->error,"\n" if $mesg->code;

	# Only continue on LDAP_SUCCESS
	$mesg->code  and last;

	my $count=0;

	foreach ($mesg->entries) {
		my $dn = $_->get_value('distinguishedName');
		my $title = $_->get_value('title');
		if(!defined($title)){ $title="none";};
		my $dept = $_->get_value('department');
		if(!defined($dept)){ $dept="none";};
		my $desc = $_->get_value('description');
		if(!defined($desc)){ $desc="none";};
		#my $pwdLastSet = $_->get_value('pwdLastSet');
		print "$count found user: $dn , title: $title, dept: $dept, desc: $desc\n";
		$query->execute($dn,$title,$dept,$desc);
#		exit if $count > 40; #for debugging so we dont have to go through all the entries
		$count++
	}



	# Get cookie from paged control
	my($resp)  = $mesg->control( LDAP_CONTROL_PAGED )  or last;
	$cookie    = $resp->cookie;

	# Only continue if cookie is nonempty (= we're not done)
	last  if (!defined($cookie) || !length($cookie));

	# Set cookie in paged control
	$page->cookie($cookie);
}

if (defined($cookie) && (length($cookie))) {
	# We had an abnormal exit, so let the server know we do not want any more
	$page->cookie($cookie);
	$page->size(0);
	$ldap->search( @args );
}



