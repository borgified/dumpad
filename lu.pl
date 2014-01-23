#!/usr/bin/env perl

#usage:
#
# lu.pl											- list all DLs
# lu.pl <string>						- search a distribution list by <string>
# lu.pl someone@actian.com	- list all the DLs this person belongs to
# lu.pl DL@actian.com				- list all the emails belonging to this DL
#
#

use warnings;
use strict;
use DBI;

my $my_cnf = '/secret/my_cnf.cnf';

my $dbh = DBI->connect("DBI:mysql:"
	. ";mysql_read_default_file=$my_cnf"
	.';mysql_read_default_group=ldap',
	undef,
	undef
) or die "something went wrong ($DBI::errstr)";


if(!defined($ARGV[0])){
	&listall;
}elsif(($ARGV[0] eq '--help')||($ARGV[0] eq '-h')){

	print	<<EOL;

#usage:
#
# lu.pl                     - list all DLs
# lu.pl <string>            - search a distribution list by <string>
# lu.pl someone\@actian.com  - list all the DLs this person belongs to
# lu.pl DL\@actian.com       - list all the emails belonging to this DL

EOL
	;
}elsif($ARGV[0] !~ /@/){
	&searchdl($ARGV[0]);
}elsif($ARGV[0] =~/@/){
	&findemail($ARGV[0]);
}else{
	print "unrecognized argument\n";
	exit;
}

sub findemail {
	my $query = $dbh->prepare("select members from ldapdl where mail = \'$ARGV[0]\'");
	$query->execute;
	while(my @row=$query->fetchrow_array){
		my $row="@row";
		my @accounts = split(/:/,
	}
}


sub searchdl {
	my $query = $dbh->prepare("select mail,name from ldapdl where name like \'%$ARGV[0]%\' or sam like \'%$ARGV[0]%\'");
	$query->execute;
	while(my($mail,$name)=$query->fetchrow_array()){
		format OUTPUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$mail,$name
.
		$~="OUTPUT";
		write;
	}
}

sub listall {
	my $query = $dbh->prepare("select mail,name from ldapdl where mail != 'none'");
	$query->execute;
	while(my($mail,$name)=$query->fetchrow_array()){
		format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$mail,$name
.
		write;
	}
}
