package mongify;
use Dancer2;
use Data::Dumper;
use URI::Escape;

use mongify::Utils;

our $VERSION = '0.1';

get '/' => sub {
    template 'Mongify 1.1 Homepage';
};

post '/configfile' => sub {
    warn '#################';
    my $params = request->params;
    warn Dumper $params;

    my $utils = mongify::Utils->new( { params => $params } );

    my $config_file = $utils->generate_config_file( $params );
    warn Dumper $config_file;

    template 'Mongify 1.0 Config File', { config_file => $config_file };
};

post '/translation' => sub {
    my $params = request->params;
    my $config_file = uri_unescape( $params->{ config_file } );
    warn Dumper $config_file;
    $config_file =~ /sql_connection.*host\s\"(.*)\"\n\t.*end.*/s;
    my $host = $1;
    $config_file =~ /sql_connection.*username\s\"(\w*|\d*)\".*end.*/s;
    my $username = $1;
    $config_file =~ /sql_connection.*password\s\"(\w+)\".*end.*/s;
    my $password = $1;
    $config_file =~ /sql_connection.*database\s\"(\w+)\".*end.*/s;
    my $database = $1;
    warn Dumper $host, $username, $password, $database;
};

true;
