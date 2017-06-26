package mongify;
use Dancer2;
use Dancer2::Plugin::Database;
use Data::Dumper;
use URI::Escape;

use mongify::Utils;

our $VERSION = '0.1';

hook 'before' => sub {
        if (! session('user') && request->path_info !~ m{^/login}) {
            redirect '/login';
        }
};

get '/login' => sub {
    # Display a login page; the original URL they requested is available as
    # vars->{requested_path}, so could be put in a hidden field in the form
    warn Dumper "IN Login";
    if ( session('user') ) {
        redirect '/';
    }
    template 'Mongify 1.0 Login.tt';
};

post '/login' => sub {
    my $user = database->quick_select('Users', 
            { username => params->{user}, password => params->{password} }
    );
    # warn Dumper params;
    warn Dumper $user;
    if (!$user) {
        warning "Failed login for unrecognised user " . params->{user};
        redirect '/login?failed=1';
    } else {
        if ( $user->{password} eq params->{password} )
        {
            debug "Password correct";
            # Logged in successfully
            session user => $user;
            redirect '/';
        } else {
            debug("Login failed - password incorrect for " . params->{user});
            redirect '/login?failed=1';
        }
    }
};

get '/logout' => sub {
    app->destroy_session;
    debug('You are logged out.');
    redirect '/login';
};

get '/' => sub {
    warn Dumper session;
    my @databases = database->quick_select('Databases', 
            { user => session->{data}->{user}->{id} }
    );
    session databases => @databases;
    warn Dumper @databases;
    template 'Mongify 1.1 Homepage', { databases => \@databases };
};

post '/' => sub {
    my $params = request->params;
    warn Dumper $params;

    database->quick_insert('Databases', { sql_adapter => $params->{adapter_sql}, sql_host => $params->{host_sql}, sql_username => $params->{username_sql}, sql_password => $params->{password_sql}, sql_database => $params->{database_sql}, mongo_host => $params->{host_nosql}, mongo_database => $params->{database_nosql}, user => session->{data}->{user}->{id} });
    redirect '/';
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
