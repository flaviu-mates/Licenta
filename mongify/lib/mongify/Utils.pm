package mongify::Utils;

use strict;
use warnings;
use Data::Dumper;
use File::Basename qw ( dirname );

sub new {
    my ( $class, $args ) = @_;

    return bless { %$args }, $class;
}

sub connect_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
       die $DBI::errstr;

    return $dbh;
}

sub init_db {
    my $db = connect_db();
    my $schema = read_file('./schema.sql');
    $db->do($schema) or die $db->errstr;
}

sub generate_config_file {
    my $self = shift;

    my $config_file = '';
    my $config_file_html='';

    $config_file .= "sql_connection do\n";
    $config_file .= "\tadapter \"$self->{database}->{sql_adapter}\"\n";
    $config_file .= "\thost \"$self->{database}->{sql_host}\"\n";
    $config_file .= "\tusername \"$self->{database}->{sql_username}\"\n";
    $config_file .= "\tpassword \"$self->{database}->{sql_password}\"\n";
    $config_file .= "\tdatabase \"$self->{database}->{sql_database}\"\n";
    $config_file .= "end\n";

    $config_file .= "mongodb_connection do\n";
    $config_file .= "\thost \"$self->{database}->{mongo_host}\"\n";
    $config_file .= "\tdatabase \"$self->{database}->{mongo_database}\"\n";
    $config_file .= "end";

    $config_file_html .= "sql_connection do<br/>";
    $config_file_html .= "&nbsp;adapter \"$self->{database}->{sql_adapter}\"<br/>";
    $config_file_html .= "&nbsp;host \"$self->{database}->{sql_host}\"<br/>";
    $config_file_html .= "&nbsp;username \"$self->{database}->{sql_username}\"<br/>";
    $config_file_html .= "&nbsp;password \"$self->{database}->{sql_password}\"<br/>";
    $config_file_html .= "&nbsp;database \"$self->{database}->{sql_database}\"<br/>";
    $config_file_html .= "end<br/>";

    $config_file_html .= "mongodb_connection do<br/>";
    $config_file_html .= "&nbsp;host \"$self->{database}->{mongo_host}\"<br/>";
    $config_file_html .= "&nbsp;database \"$self->{database}->{mongo_database}\"<br/>";
    $config_file_html .= "end";

    return { config_file => $config_file, config_file_html => $config_file_html };
}

sub write_config_file {
    my $self = shift;

    my $filename = "database_".$self->{user_id}.".config";
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh "sql_connection do\n";
    print $fh "\tadapter \"$self->{database}->{sql_adapter}\"\n";
    print $fh "\thost \"$self->{database}->{sql_host}\"\n";
    print $fh "\tusername \"$self->{database}->{sql_username}\"\n";
    print $fh "\tpassword \"$self->{database}->{sql_password}\"\n";
    print $fh "\tdatabase \"$self->{database}->{sql_database}\"\n";
    print $fh "end\n";

    print $fh "mongodb_connection do\n";
    print $fh "\thost \"$self->{database}->{mongo_host}\"\n";
    print $fh "\tdatabase \"$self->{database}->{mongo_database}\"\n";
    print $fh "end";

    close $fh;

    return $filename;
}

1;