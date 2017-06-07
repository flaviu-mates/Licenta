package mongify::Utils;

use strict;
use warnings;
use Data::Dumper;

sub new {
    my ( $class, $args ) = @_;

    return bless { %$args }, $class;
}

sub generate_config_file {
    my $self = shift;

    my $config_file = '';
    my $config_file_html='';
    warn Dumper $self->{ params };

    $config_file .= "sql_connection do\n";
    $config_file .= "\tadapter \"$self->{params}->{adapter_sql}\"\n";
    $config_file .= "\thost \"$self->{params}->{host_sql}\"\n";
    $config_file .= "\tusername \"$self->{params}->{username_sql}\"\n";
    $config_file .= "\tpassword \"$self->{params}->{password_sql}\"\n";
    $config_file .= "\tdatabase \"$self->{params}->{database_sql}\"\n";
    $config_file .= "end\n";

    $config_file .= "mongodb_connection do\n";
    $config_file .= "\thost \"$self->{params}->{host_nosql}\"\n";
    $config_file .= "\tdatabase \"$self->{params}->{database_nosql}\"\n";
    $config_file .= "end";

    $config_file_html .= "sql_connection do<br/>";
    $config_file_html .= "&nbsp;adapter \"$self->{params}->{adapter_sql}\"<br/>";
    $config_file_html .= "&nbsp;host \"$self->{params}->{host_sql}\"<br/>";
    $config_file_html .= "&nbsp;username \"$self->{params}->{username_sql}\"<br/>";
    $config_file_html .= "&nbsp;password \"$self->{params}->{password_sql}\"<br/>";
    $config_file_html .= "&nbsp;database \"$self->{params}->{database_sql}\"<br/>";
    $config_file_html .= "end<br/>";

    $config_file_html .= "mongodb_connection do<br/>";
    $config_file_html .= "&nbsp;host \"$self->{params}->{host_nosql}\"<br/>";
    $config_file_html .= "&nbsp;database \"$self->{params}->{database_nosql}\"<br/>";
    $config_file_html .= "end";

    return { config_file => $config_file, config_file_html => $config_file_html };
}

1;