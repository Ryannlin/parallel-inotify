#!/usr/bin/perl -w

=head1 NAME

sql - execute a command on a database determined by a dburl

=head1 SYNOPSIS

B<sql> [options] I<dburl> [I<commands>]

B<sql> [options] I<dburl> < commandfile

B<#!/usr/bin/sql> B<--shebang> [options] I<dburl>

=head1 DESCRIPTION

GNU B<sql> aims to give a simple, unified interface for accessing
databases through all the different databases' command line
clients. So far the focus has been on giving a common way to specify
login information (protocol, username, password, hostname, and port
number), size (database and table size), and running queries.

The database is addressed using a DBURL. If I<commands> are left out
you will get that database's interactive shell.

GNU B<sql> is often used in combination with GNU B<parallel>.

=over 9

=item I<dburl>

A DBURL has the following syntax:
[sql:]vendor://
[[user][:password]@][host][:port]/[database][?sqlquery]

See the section DBURL below.

=item I<commands>

The SQL commands to run. Each argument will have a newline
appended.

Example: "SELECT * FROM foo;" "SELECT * FROM bar;"

If the arguments contain '\n' or '\x0a' this will be replaced with a
newline:

Example: "SELECT * FROM foo;\n SELECT * FROM bar;"

If no commands are given SQL is read from the keyboard or STDIN.

Example: echo 'SELECT * FROM foo;' | sql mysql:///


=item B<--db-size>

=item B<--dbsize>

Size of database. Show the size of the database on disk. For Oracle
this requires access to read the table I<dba_data_files> - the user
I<system> has that.


=item B<--help>

=item B<-h>

Print a summary of the options to GNU B<sql> and exit.


=item B<--html>

HTML output. Turn on HTML tabular output.


=item B<--show-processlist>

=item B<--proclist>

=item B<--listproc>

Show the list of running queries.


=item B<--show-databases>

=item B<--showdbs>

=item B<--list-databases>

=item B<--listdbs>

List the databases (table spaces) in the database.


=item B<--show-tables>

=item B<--list-tables>

=item B<--table-list>

List the tables in the database.


=item B<--noheaders>

=item B<--no-headers>

=item B<-n>

Remove headers and footers and print only tuples. Bug in Oracle: it
still prints number of rows found.


=item B<-p> I<pass-through>

The string following -p will be given to the database connection
program as arguments. Multiple -p's will be joined with
space. Example: pass '-U' and the user name to the program:

I<-p "-U scott"> can also be written I<-p -U -p scott>.


=item B<-r>

Try 3 times. Short version of I<--retries 3>.


=item B<--retries> I<ntimes>

Try I<ntimes> times. If the client program returns with an error,
retry the command. Default is I<--retries 1>.


=item B<--sep> I<string>

=item B<-s> I<string>

Field separator. Use I<string> as separator between columns.


=item B<--skip-first-line>

Do not use the first line of input (used by GNU B<sql> itself
when called with B<--shebang>).


=item B<--table-size>

=item B<--tablesize>

Size of tables. Show the size of the tables in the database.


=item B<--verbose>

=item B<-v>

Print which command is sent.


=item B<--version>

=item B<-V>

Print the version GNU B<sql> and exit.


=item B<--shebang>

=item B<-Y>

GNU B<sql> can be called as a shebang (#!) command as the first line of a script. Like this:

  #!/usr/bin/sql -Y mysql:///

  SELECT * FROM foo;

For this to work B<--shebang> or B<-Y> must be set as the first option.

=back

=head1 DBURL

A DBURL has the following syntax:
[sql:]vendor://
[[user][:password]@][host][:port]/[database][?sqlquery]

To quote special characters use %-encoding specified in
http://tools.ietf.org/html/rfc3986#section-2.1 (E.g. a password
containing '/' would contain '%2F').

Examples:
 mysql://scott:tiger@my.example.com/mydb
 sql:oracle://scott:tiger@ora.example.com/xe
 postgresql://scott:tiger@pg.example.com/pgdb
 pg:///
 postgresqlssl://scott@pg.example.com:3333/pgdb
 sql:sqlite2:////tmp/db.sqlite?SELECT * FROM foo;
 sqlite3:///../db.sqlite3?SELECT%20*%20FROM%20foo;

Currently supported vendors: MySQL (mysql), MySQL with SSL (mysqls,
mysqlssl), Oracle (oracle, ora), PostgreSQL (postgresql, pg, pgsql,
postgres), PostgreSQL with SSL (postgresqlssl, pgs, pgsqlssl,
postgresssl, pgssl, postgresqls, pgsqls, postgress), SQLite2 (sqlite,
sqlite2), SQLite3 (sqlite3).

Aliases must start with ':' and are read from
/etc/sql/aliases and ~/.sql/aliases. The user's own
~/.sql/aliases should only be readable by the user.

Example of aliases:

 :myalias1 pg://scott:tiger@pg.example.com/pgdb
 :myalias2 ora://scott:tiger@ora.example.com/xe
 # Short form of mysql://`whoami`:nopassword@localhost:3306/`whoami`
 :myalias3 mysql:///
 # Short form of mysql://`whoami`:nopassword@localhost:33333/mydb
 :myalias4 mysql://:33333/mydb
 # Alias for an alias
 :m      :myalias4
 # the sortest alias possible
 :       sqlite2:////tmp/db.sqlite
 # Including an SQL query
 :query  sqlite:////tmp/db.sqlite?SELECT * FROM foo;

=head1 EXAMPLES

=head2 Get an interactive prompt

The most basic use of GNU B<sql> is to get an interactive prompt:

B<sql sql:oracle://scott:tiger@ora.example.com/xe>

If you have setup an alias you can do:

B<sql :myora>


=head2 Run a query

To run a query directly from the command line:

B<sql :myalias "SELECT * FROM foo;">

Oracle requires newlines after each statement. This can be done like
this:

B<sql :myora "SELECT * FROM foo;" "SELECT * FROM bar;">

Or this:

B<sql :myora "SELECT * FROM foo;\nSELECT * FROM bar;">


=head2 Copy a PostgreSQL database

To copy a PostgreSQL database use pg_dump to generate the dump and GNU
B<sql> to import it:

B<pg_dump pg_database | sql pg://scott:tiger@pg.example.com/pgdb>


=head2 Empty all tables in a MySQL database

Using GNU B<parallel> it is easy to empty all tables without dropping them:

B<sql -n mysql:/// 'show tables' | parallel sql mysql:/// DELETE FROM {};>


=head2 Drop all tables in a PostgreSQL database

To drop all tables in a PostgreSQL database do:

B<sql -n pg:/// '\dt' | parallel --colsep '\|' -r sql pg:/// DROP TABLE {2};>


=head2 Run as a script

Instead of doing:

B<sql mysql:/// < sqlfile>

you can combine the sqlfile with the DBURL to make a
UNIX-script. Create a script called I<demosql>:

B<#!/usr/bin/sql -Y mysql:///>

B<SELECT * FROM foo;>

Then do:

B<chmod +x demosql; ./demosql>


=head2 Use --colsep to process multiple columns

Use GNU B<parallel>'s B<--colsep> to separate columns:

B<sql -s '\t' :myalias 'SELECT * FROM foo;' | parallel --colsep '\t' do_stuff {4} {1}>


=head2 Retry if the connection fails

If the access to the database fails occasionally B<--retries> can help
make sure the query succeeds:

B<sql --retries 5 :myalias 'SELECT * FROM really_big_foo;'>


=head2 Get info about the running database system

Show how big the database is:

B<sql --db-size :myalias>

List the tables:

B<sql --list-tables :myalias>

List the size of the tables:

B<sql --table-size :myalias>

List the running processes:

B<sql --show-processlist :myalias>


=head1 REPORTING BUGS

GNU B<sql> is part of GNU B<parallel>. Report bugs to <bug-parallel@gnu.org>.


=head1 AUTHOR

When using GNU B<sql> for a publication please cite:

O. Tange (2011): GNU SQL - A Command Line Tool for Accessing Different
Databases Using DBURLs, ;login: The USENIX Magazine, April 2011:29-32.

Copyright (C) 2008,2009,2010 Ole Tange http://ole.tange.dk

Copyright (C) 2010,2011,2012,2013,2014,2015,2016,2017,2018 Ole Tange,
http://ole.tange.dk and Free Software Foundation, Inc.

=head1 LICENSE

Copyright (C) 2007,2008,2009,2010,2011 Free Software Foundation, Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
at your option any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head2 Documentation license I

Permission is granted to copy, distribute and/or modify this documentation
under the terms of the GNU Free Documentation License, Version 1.3 or
any later version published by the Free Software Foundation; with no
Invariant Sections, with no Front-Cover Texts, and with no Back-Cover
Texts.  A copy of the license is included in the file fdl.txt.

=head2 Documentation license II

You are free:

=over 9

=item B<to Share>

to copy, distribute and transmit the work

=item B<to Remix>

to adapt the work

=back

Under the following conditions:

=over 9

=item B<Attribution>

You must attribute the work in the manner specified by the author or
licensor (but not in any way that suggests that they endorse you or
your use of the work).

=item B<Share Alike>

If you alter, transform, or build upon this work, you may distribute
the resulting work only under the same, similar or a compatible
license.

=back

With the understanding that:

=over 9

=item B<Waiver>

Any of the above conditions can be waived if you get permission from
the copyright holder.

=item B<Public Domain>

Where the work or any of its elements is in the public domain under
applicable law, that status is in no way affected by the license.

=item B<Other Rights>

In no way are any of the following rights affected by the license:

=over 9

=item *

Your fair dealing or fair use rights, or other applicable
copyright exceptions and limitations;

=item *

The author's moral rights;

=item *

Rights other persons may have either in the work itself or in
how the work is used, such as publicity or privacy rights.

=back

=item B<Notice>

For any reuse or distribution, you must make clear to others the
license terms of this work.

=back

A copy of the full license is included in the file as cc-by-sa.txt.

=head1 DEPENDENCIES

GNU B<sql> uses Perl. If B<mysql> is installed, MySQL dburls will
work. If B<psql> is installed, PostgreSQL dburls will work.  If
B<sqlite> is installed, SQLite2 dburls will work.  If B<sqlite3> is
installed, SQLite3 dburls will work. If B<sqlplus> is installed,
Oracle dburls will work. If B<rlwrap> is installed, GNU B<sql> will
have a command history for Oracle.


=head1 FILES

~/.sql/aliases - user's own aliases with DBURLs

/etc/sql/aliases - common aliases with DBURLs


=head1 SEE ALSO

B<mysql>(1), B<psql>(1), B<rlwrap>(1), B<sqlite>(1), B<sqlite3>(1), B<sqlplus>(1)

=cut

use Getopt::Long;
use strict;
use File::Temp qw/tempfile tempdir/;

parse_options();

my $pass_through_options = (defined $::opt_p) ? join(" ",@{$::opt_p}) : "";
my $dburl_or_alias = shift;
if (not defined $dburl_or_alias) {
    Usage("No DBURL given");
    exit -1;
}
my %dburl = parse_dburl(get_alias($dburl_or_alias));

my $interactive_command;
my $batch_command;

my $database_driver = database_driver_alias($dburl{'databasedriver'});
if($database_driver eq "mysql" or
   $database_driver eq "mysqlssl") {
    ($batch_command,$interactive_command) = mysql_commands($database_driver,%dburl);
} elsif($database_driver eq "postgresql" or
	$database_driver eq "postgresqlssl") {
    ($batch_command,$interactive_command) = postgresql_commands($database_driver,%dburl);
} elsif($database_driver eq "oracle") {
    ($batch_command,$interactive_command) = oracle_commands($database_driver,%dburl);
} elsif($database_driver eq "sqlite" or
	$database_driver eq "sqlite3") {
    ($batch_command,$interactive_command) = sqlite_commands($database_driver,%dburl);
}

my $err;
my $retries;
$retries ||= defined $::opt_retries ? $::opt_retries : undef;
$retries ||= defined $::opt_retry ? $::opt_retry * 3 : undef;
$retries ||= 1;

if(defined $::opt_processlist) {
    unshift @ARGV, processlist($database_driver,%dburl);
}

if(defined $::opt_tablelist) {
    unshift @ARGV, tablelist($database_driver,%dburl);
}

if(defined $::opt_dblist) {
    unshift @ARGV, dblist($database_driver,%dburl);
}

if(defined $::opt_dbsize) {
    unshift @ARGV, dbsize($database_driver,%dburl);
}

if(defined $::opt_tablesize) {
    unshift @ARGV, tablesize($database_driver,%dburl);
}

my $queryfile = "";
if($dburl{'query'}) {
    my $fh;
    ($fh,$queryfile) = tempfile(SUFFIX => ".sql");
    print $fh $dburl{'query'},"\n";
    close $fh;
    $batch_command = "(cat $queryfile;rm $queryfile; cat) | $batch_command";
}

do {
    if (is_stdin_terminal()) {
	if(@ARGV) {
	    open(M,"| $batch_command") || die("mysql/psql/sqlplus not in path");
	    for(@ARGV) {
		s/\\n/\n/g;
		s/\\x0a/\n/gi;
		print M "$_\n";
	    }
	    close M;
	} else {
	    $::opt_debug and print "$interactive_command\n";
	    $::opt_verbose and print "$interactive_command\n";
	    system("$interactive_command");
	}
    } else {
	if(@ARGV) {
	    open(M,"| $batch_command") || die("mysql/psql/sqlplus not in path");
	    for(@ARGV) {
		s/\\n/\n/g;
		s/\\x0a/\n/gi;
		print M "$_\n";
	    }
	    close M;
	} else {
	    $::opt_debug and print "$batch_command\n";
	    $::opt_verbose and print "$batch_command\n";
	    system("$batch_command");
	}
    }
    $err = $?>>8;
} while (--$retries and $err);

$queryfile and unlink $queryfile;

$Global::Initfile && unlink $Global::Initfile;
exit ($err);

sub parse_options {
    $Global::version = 20180922;
    $Global::progname = 'sql';

    # This must be done first as this may exec myself
    if(defined $ARGV[0] and ($ARGV[0]=~/^-Y/ or $ARGV[0]=~/^--shebang /)) {
	# Program is called from #! line in script
	$ARGV[0]=~s/^-Y //; # remove -Y if on its own
	$ARGV[0]=~s/^-Y/-/; # remove -Y if bundled with other options
	$ARGV[0]=~s/^--shebang //; # remove --shebang if it is set
	my $argfile = pop @ARGV;
	# exec myself to split @ARGV into separate fields
	exec "$0 --skip-first-line < $argfile @ARGV";
    }
    Getopt::Long::Configure ("bundling","require_order");
    GetOptions("passthrough|p=s@" => \$::opt_p,
	       "sep|s=s" => \$::opt_s,
	       "html" => \$::opt_html,
	       "show-processlist|proclist|listproc" => \$::opt_processlist,
	       "show-tables|showtables|listtables|list-tables|tablelist|table-list"
	       => \$::opt_tablelist,
	       "dblist|".
	       "listdb|listdbs|list-db|list-dbs|list-database|".
	       "list-databases|listdatabases|listdatabase|showdb|".
	       "showdbs|show-db|show-dbs|show-database|show-databases|".
	       "showdatabases|showdatabase" => \$::opt_dblist,
	       "db-size|dbsize" => \$::opt_dbsize,
	       "table-size|tablesize" => \$::opt_tablesize,
	       "noheaders|no-headers|n" => \$::opt_n,
	       "r" => \$::opt_retry,
	       "retries=s" => \$::opt_retries,
	       "debug|D" => \$::opt_debug,
	       # Shebang #!/usr/bin/parallel -Yotheroptions
	       "Y|shebang" => \$::opt_shebang,
	       "skip-first-line" => \$::opt_skip_first_line,
	       # GNU requirements
	       "help|h" => \$::opt_help,
	       "version|V" => \$::opt_version,
	       "verbose|v" => \$::opt_verbose,
	) || die_usage();

    if(defined $::opt_help) { die_usage(); }
    if(defined $::opt_version) { version(); exit(0); }
    $Global::debug = $::opt_debug;
}

sub database_driver_alias {
    my $driver = shift;
    my %database_driver_alias = ("mysql" => "mysql",
				 "mysqls" => "mysqlssl",
				 "mysqlssl" => "mysqlssl",
				 "oracle" => "oracle",
				 "ora" => "oracle",
				 "oracles" => "oraclessl",
				 "oras" => "oraclessl",
				 "oraclessl" => "oraclessl",
				 "orassl" => "oraclessl",
				 "postgresql" => "postgresql",
				 "pgsql" => "postgresql",
				 "postgres" => "postgresql",
				 "pg" => "postgresql",
				 "postgresqlssl" => "postgresqlssl",
				 "pgsqlssl" => "postgresqlssl",
				 "postgresssl" => "postgresqlssl",
				 "pgssl" => "postgresqlssl",
				 "postgresqls" => "postgresqlssl",
				 "pgsqls" => "postgresqlssl",
				 "postgress" => "postgresqlssl",
				 "pgs" => "postgresqlssl",
				 "sqlite" => "sqlite",
				 "sqlite2" => "sqlite",
				 "sqlite3" => "sqlite3",
	);
    return $database_driver_alias{$driver};
}

sub mysql_commands {
    my ($database_driver,%opt) = (@_);
    find_command_in_path("mysql") || die ("mysql not in path");
    if(defined($::opt_s)) { die "Field separator not implemented for mysql" }
    my $password = defined($opt{'password'}) ? "--password=".$opt{'password'} : "";
    my $host = defined($opt{'host'}) ? "--host=".$opt{'host'} : "";
    my $port = defined($opt{'port'}) ? "--port=".$opt{'port'} : "";
    my $user = defined($opt{'user'}) ? "--user=".$opt{'user'} : "";
    my $database = defined($opt{'database'}) ? $opt{'database'} : $ENV{'USER'};
    my $html = defined($::opt_html) ? "--html" : "";
    my $no_headers = defined($::opt_n) ? "--skip-column-names" : "";
    my $ssl = "";
    if ($database_driver eq "mysqlssl") {
	$ssl="--ssl";
    }
    my($credential_fh,$tmp) = tempfile(SUFFIX => ".sql");
    chmod (0600,$tmp);
    print $credential_fh ("[client]\n",
			  $user && "user=$opt{'user'}\n",
			  $password && "password=$opt{'password'}\n",
			  $host && "host=$opt{'host'}\n");
    close $credential_fh;

    # Prepend with a remover of the credential tempfile
    # -C: Compression if both ends support it
    $batch_command =
	"((sleep 1; rm $tmp) & ".
	"mysql --defaults-extra-file=$tmp -C $pass_through_options $no_headers $html $ssl $host $user $port  $database)";
    $interactive_command = $batch_command;
    return($batch_command,$interactive_command);
}

sub postgresql_commands {
    my ($database_driver,%opt) = (@_);
    find_command_in_path("psql") || die ("psql not in path");
    my $sep = ($::opt_s) ? "-A --field-separator '$::opt_s'" : "";
    my $password = defined($opt{'password'}) ? "PGPASSWORD=".$opt{'password'} : "";
    my $host = defined($opt{'host'}) ? "-h ".$opt{'host'} : "";
    my $port = defined($opt{'port'}) ? "-p ".$opt{'port'} : "";
    my $user = defined($opt{'user'}) ? "-U ".$opt{'user'} : "";
    my $database = defined($opt{'database'}) ? "-d ".$opt{'database'} : "";
    my $html = defined($::opt_html) ? "--html" : "";
    my $no_headers = defined($::opt_n) ? "--tuples-only" : "";
    my $ssl = "";
    if ($database_driver eq "postgresqlssl") {
	$ssl="PGSSLMODE=require";
    }
    $batch_command =
	"$ssl $password psql $pass_through_options $sep $no_headers $html $host $user $port $database";
    $interactive_command = $batch_command;

    return($batch_command,$interactive_command);
}

sub oracle_commands {
    my ($database_driver,%opt) = (@_);
    # oracle://user:pass@grum:1521/XE becomes:
    # sqlplus 'user/pass@(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = grum)(PORT = 1521)) (CONNECT_DATA =(SERVER = DEDICATED)(SERVICE_NAME = XE) ))'
    my $sqlplus = find_command_in_path("sqlplus") ||
	find_command_in_path("sqlplus64") or
	die ("sqlplus/sqlplus64 not in path");

    # Readline support: if rlwrap installed run rlwrap sqlplus
    my $rlwrap = find_command_in_path("rlwrap");

    # Set good defaults in the inifile
    $Global::Initfile = "/tmp/$$.sql.init";
    open(INIT,">".$Global::Initfile) || die;
    print INIT "SET LINESIZE 32767\n";
    $::opt_debug and print "SET LINESIZE 32767\n";
    print INIT "SET WRAP OFF\n";
    $::opt_debug and print "SET WRAP OFF\n";
    if(defined($::opt_html)) {
	print INIT "SET MARK HTML ON\n";
	$::opt_debug and print "SET MARK HTML ON\n";
    }
    if(defined($::opt_n)) {
	print INIT "SET PAGES 0\n";
	$::opt_debug and print "SET PAGES 0\n";
    } else {
	print INIT "SET PAGES 50000\n";
	$::opt_debug and print "SET PAGES 50000\n";
    }
    if(defined($::opt_s)) {
	print INIT "SET COLSEP $::opt_s\n";
	$::opt_debug and print "SET COLSEP $::opt_s\n";
    }
    close INIT;

    my $password = defined($opt{'password'}) ? "/".$opt{'password'} : "";
    my $host = defined($opt{'host'}) ? $opt{'host'} : "localhost";
    my $port = defined($opt{'port'}) ? $opt{'port'} : "1521";
    my $user = defined($opt{'user'}) ? $opt{'user'} : "";
    # Database is called service in Oracle lingo
    my $service = defined($opt{'database'}) ? "(SERVICE_NAME = ".$opt{'database'}.")" : "";
    my $tns = "(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = $host)(PORT = $port)) ".
	"(CONNECT_DATA =(SERVER = DEDICATED)$service ))";
    my $ssl = "";
    # -L: Do not re-ask for password if it is wrong
    my $common_options = "-L $pass_through_options '$user$password\@$tns' \@$Global::Initfile";
    my $batch_command =	"$sqlplus -S ".$common_options;
    my $interactive_command = "$rlwrap $sqlplus ".$common_options;
    return($batch_command,$interactive_command);
}

sub sqlite_commands {
    my ($database_driver,%opt) = (@_);
    if(not find_command_in_path($database_driver)) {
	print STDERR "Database driver '$database_driver' not supported\n";
	exit -1;
    }
    my $sep = defined($::opt_s) ? "-separator '$::opt_s'" : "";
    my $password = defined($opt{'password'}) ? "--password=".$opt{'password'} : "";
    my $host = defined($opt{'host'}) ? "--host=".$opt{'host'} : "";
    my $port = defined($opt{'port'}) ? "--port=".$opt{'port'} : "";
    my $user = defined($opt{'user'}) ? "--user=".$opt{'user'} : "";
    my $database = defined($opt{'database'}) ? $opt{'database'} : "";
    my $html = defined($::opt_html) ? "-html" : "";
    my $no_headers = defined($::opt_n) ? "-noheader" : "-header";
    my $ssl = "";
    $batch_command =
	"$database_driver $pass_through_options $sep $no_headers $html $database";
    $interactive_command = $batch_command;
    return($batch_command,$interactive_command);
}


# Return the code for 'show processlist' in the chosen database dialect
sub processlist {
    my $dbdriver = shift;
    my %dburl = @_;
    my %statement =
	("mysql" => "show processlist;",
	 "postgresql" => ("SELECT ".
			  "    datname AS database,".
			  "    usename AS username,".
			  "    now()-xact_start AS runtime,".
			  "    current_query ".
			  "FROM pg_stat_activity ".
			  "ORDER BY runtime DESC;"),
	 "oracle" => ("SELECT ".
		      '    CPU_TIME/100000, SYS.V_$SQL.SQL_TEXT, USERNAME '.
		      "FROM ".
		      '    SYS.V_$SQL, SYS.V_$SESSION '.
		      "WHERE ".
		      '    SYS.V_$SQL.SQL_ID = SYS.V_$SESSION.SQL_ID(+) '.
		      "AND username IS NOT NULL ".
		      "ORDER BY CPU_TIME DESC;"),
	);
    if($statement{$dbdriver}) {
	return $statement{$dbdriver};
    } else {
	print STDERR "processlist is not implemented for $dbdriver\n";
	exit 1;
    }
}

# Return the code for 'show tables' in the chosen database dialect
sub tablelist {
    my $dbdriver = shift;
    my %dburl = @_;
    my %statement =
	("mysql" => "show tables;",
	 "postgresql" => '\dt',
	 "oracle" => ("SELECT object_name FROM user_objects WHERE object_type = 'TABLE';"),
	 "sqlite" => ".tables",
	 "sqlite3" => ".tables",
	);
    if($statement{$dbdriver}) {
	return $statement{$dbdriver};
    } else {
	print STDERR "tablelist is not implemented for $dbdriver\n";
	exit 1;
    }
}

# Return the code for 'show databases' in the chosen database dialect
sub dblist {
    my $dbdriver = shift;
    my %dburl = @_;
    my %statement =
	("mysql" => "show databases;",
	 "postgresql" => ("SELECT datname FROM pg_database ".
			  "WHERE datname NOT IN ('template0','template1','postgres') ".
			  "ORDER BY datname ASC;"),
	 "oracle" => ("select * from user_tablespaces;"),
	);
    if($statement{$dbdriver}) {
	return $statement{$dbdriver};
    } else {
	print STDERR "dblist is not implemented for $dbdriver\n";
	exit 1;
    }
}

# Return the code for 'show database size' in the chosen database dialect
sub dbsize {
    my $dbdriver = shift;
    my %dburl = @_;
    my %statement;
    if(defined $dburl{'database'}) {
	%statement =
	    ("mysql" => (
		 'SELECT '.
		 '    table_schema "database", '.
		 '    SUM(data_length+index_length) "bytes", '.
		 '    SUM(data_length+index_length)/1024/1024 "megabytes" '.
		 'FROM information_schema.TABLES '.
		 "WHERE table_schema = '$dburl{'database'}'".
		 'GROUP BY table_schema;'),
	     "postgresql" => (
		 "SELECT '$dburl{'database'}' AS database, ".
		 "pg_database_size('$dburl{'database'}') AS bytes, ".
		 "pg_size_pretty(pg_database_size('$dburl{'database'}')) AS human_readabable "),
	     "sqlite" => (
		 "SELECT ".(undef_as_zero(-s $dburl{'database'}))." AS bytes;"),
	     "sqlite3" => (
		 "SELECT ".(undef_as_zero(-s $dburl{'database'}))." AS bytes;"),
	    );
    } else {
	%statement =
	    ("mysql" => (
		 'SELECT '.
		 '    table_schema "database", '.
		 '    SUM(data_length+index_length) "bytes", '.
		 '    SUM(data_length+index_length)/1024/1024 "megabytes" '.
		 'FROM information_schema.TABLES '.
		 'GROUP BY table_schema;'),
	     "postgresql" => (
		 'SELECT datname AS database, pg_database_size(datname) AS bytes, '.
		 'pg_size_pretty(pg_database_size(datname)) AS human_readabable '.
		 'FROM (SELECT datname FROM pg_database) a;'),
	     "sqlite" => (
		 "SELECT 0 AS bytes;"),
	     "sqlite3" => (
		 "SELECT 0 AS bytes;"),
	    );
    }
    if($statement{$dbdriver}) {
	return $statement{$dbdriver};
    } else {
	print STDERR "dbsize is not implemented for $dbdriver\n";
	exit 1;
    }
}


# Return the code for 'show table size' in the chosen database dialect
sub tablesize {
    my $dbdriver = shift;
    my $database = shift;
    my %statement =
	("postgresql" => (
	     "SELECT relname, relpages*8 AS kb, reltuples::int AS \"live+dead rows\" ".
	     "FROM pg_class c ".
	     "ORDER BY relpages DESC;"),
	 "mysql" => (
	     "select table_name, TABLE_ROWS, DATA_LENGTH,INDEX_LENGTH from INFORMATION_SCHEMA.tables;"),
	);
    if($statement{$dbdriver}) {
	return $statement{$dbdriver};
    } else {
	print STDERR "table size is not implemented for $dbdriver\n";
	exit 1;
    }
}

sub is_stdin_terminal {
    return (-t STDIN);
}

sub find_command_in_path {
    # Find the command if it exists in the current path
    my $command = shift;
    my $path = `which $command`;
    chomp $path;
    return $path;
}

sub Usage {
    if(@_) {
	print "Error:\n";
	print map{ "$_\n" } @_;
	print "\n";
    }
    print "sql [-hnr] [--table-size] [--db-size] [-p pass-through] [-s string] dburl [command]\n";
}

sub get_alias {
    my $alias = shift;
    $alias =~ s/^(sql:)*//; # Accept aliases prepended with sql:
    if ($alias !~ /^:/) {
	return $alias;
    }

    # Find the alias
    my $path;
    if (-l $0) {
	($path) = readlink($0) =~ m|^(.*)/|;
    } else {
	($path) = $0 =~ m|^(.*)/|;
    }

    my @deprecated = ("$ENV{HOME}/.dburl.aliases",
		      "$path/dburl.aliases", "$path/dburl.aliases.dist");
    for (@deprecated) {
	if(-r $_) {
	    print STDERR "$_ is deprecated. Use .sql/aliases instead (read man sql)\n";
	}
    }
    my @urlalias=();
    check_permissions("$ENV{HOME}/.sql/aliases");
    check_permissions("$ENV{HOME}/.dburl.aliases");
    my @search = ("$ENV{HOME}/.sql/aliases",
		  "$ENV{HOME}/.dburl.aliases", "/etc/sql/aliases",
		  "$path/dburl.aliases", "$path/dburl.aliases.dist");
    for my $alias_file (@search) {
	if(-r $alias_file) {
	    push @urlalias, `cat "$alias_file"`;
	}
    }
    my ($alias_part,$rest) = $alias=~/(:\w*)(.*)/;
    # If we saw this before: we have an alias loop
    if(grep {$_ eq $alias_part } @Private::seen_aliases) {
	print STDERR "$alias_part is a cyclic alias\n";
	exit -1;
    } else {
	push @Private::seen_aliases, $alias_part;
    }

    my $dburl;
    for (@urlalias) {
	/^$alias_part\s+(\S+.*)/ and do { $dburl = $1; last; }
    }

    if($dburl) {
	return get_alias($dburl.$rest);
    } else {
	Usage("$alias is not defined in @search");
	exit(-1);
    }
}

sub check_permissions {
    my $file = shift;

    if(-e $file) {
	if(not -o $file) {
	    my $username = (getpwuid($<))[0];
	    print STDERR "$file should be owned by $username: chown $username $file\n";
	}
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	    $atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
	if($mode & 077) {
	    my $username = (getpwuid($<))[0];
	    print STDERR "$file should be only be readable by $username: chmod 600 $file\n";
	}
    }
}

sub parse_dburl {
    my $url = shift;
    my %options = ();
    # sql:mysql://[[user][:password]@][host][:port]/[database[?sql query]]

    if($url=~m!(?:sql:)? # You can prefix with 'sql:'
               ((?:oracle|ora|mysql|pg|postgres|postgresql)(?:s|ssl|)|
                 (?:sqlite|sqlite2|sqlite3)):// # Databasedriver ($1)
               (?:
                ([^:@/][^:@]*|) # Username ($2)
                (?:
                 :([^@]*) # Password ($3)
                )?
               @)?
               ([^:/]*)? # Hostname ($4)
               (?:
                :
                ([^/]*)? # Port ($5)
               )?
               (?:
                /
                ([^?/]*)? # Database ($6)
               )?
               (?:
                /?
                \?
                (.*)? # Query ($7)
               )?
              !x) {
	$options{databasedriver} = undef_if_empty(uri_unescape($1));
	$options{user} = undef_if_empty(uri_unescape($2));
	$options{password} = undef_if_empty(uri_unescape($3));
	$options{host} = undef_if_empty(uri_unescape($4));
	$options{port} = undef_if_empty(uri_unescape($5));
	$options{database} = undef_if_empty(uri_unescape($6))
	    || $options{user};
	$options{query} = undef_if_empty(uri_unescape($7));
	debug("dburl $url\n");
	debug("databasedriver ",$options{databasedriver}, " user ", $options{user},
	      " password ", $options{password}, " host ", $options{host},
	      " port ", $options{port}, " database ", $options{database},
	      " query ",$options{query}, "\n");
    } else {
	Usage("$url is not a valid DBURL");
	exit -1;
    }
    return %options;
}

sub uri_unescape {
    # Copied from http://cpansearch.perl.org/src/GAAS/URI-1.55/URI/Escape.pm
    # to avoid depending on URI::Escape
    # This section is (C) Gisle Aas.
    # Note from RFC1630:  "Sequences which start with a percent sign
    # but are not followed by two hexadecimal characters are reserved
    # for future extension"
    my $str = shift;
    if (@_ && wantarray) {
	# not executed for the common case of a single argument
	my @str = ($str, @_);  # need to copy
	foreach (@str) {
	    s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	return @str;
    }
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg if defined $str;
    $str;
}

sub undef_if_empty {
    if(defined($_[0]) and $_[0] eq "") {
	return undef;
    }
    return $_[0];
}

sub undef_as_zero {
    my $a = shift;
    return $a ? $a : 0;
}

sub version {
    # Returns: N/A
    print join("\n",
	       "GNU $Global::progname $Global::version",
	       "Copyright (C) 2009,2010,2011,2012,2013,2014,2015,2016,2017",
	       "Ole Tange and Free Software Foundation, Inc.",
	       "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>",
	       "This is free software: you are free to change and redistribute it.",
	       "GNU $Global::progname comes with no warranty.",
	       "",
	       "Web site: http://www.gnu.org/software/${Global::progname}\n",
	       "When using GNU $Global::progname for a publication please cite:\n",
	       "O. Tange (2011): GNU SQL - A Command Line Tool for Accessing Different",
	       "Databases Using DBURLs, ;login: The USENIX Magazine, April 2011:29-32.\n"
	);
}

sub die_usage {
    # Returns: N/A
    usage();
    exit(255);
}

sub usage {
    # Returns: N/A
    print "Usage:\n";
    print "$Global::progname [options] dburl [sqlcommand]\n";
    print "$Global::progname [options] dburl < sql_command_file\n";
    print "\n";
    print "See 'man $Global::progname' for the options\n";
}

sub debug {
    # Returns: N/A
    $Global::debug or return;
    @_ = grep { defined $_ ? $_ : "" } @_;
    print @_;
}

$::opt_skip_first_line = $::opt_shebang = 0;
