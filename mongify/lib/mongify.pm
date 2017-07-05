package mongify;
use Dancer2;
use Dancer2::Plugin::Database;
use Data::Dumper;
use URI::Escape;
use IPC::Run3;

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

    my @history_databases = database->quick_select('Databases_history', 
            { user => session->{data}->{user}->{id} }
    );
    session databases => \@databases, databases_history => \@history_databases;
    warn Dumper @databases;
    template 'Mongify 1.1 Homepage', { databases => \@databases, history_databases => \@history_databases };
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
    warn Dumper $params->{delete},"PARAMSSSSSSSSSSSs*&^Y";


    if ( $params->{delete} eq '1' && $params->{ database_id } ) {
        warn 'NORMALLLLLLLLLLLLLLLLLLLLLLL';
        database->quick_delete('Databases', { id => $params->{ database_id } });
        redirect '/';
    }
    elsif ( $params->{delete} eq '1' && $params->{ history_id } ){
        warn 'HISTORYYYYYYYYYYYYYYYYYYY';
        database->quick_delete('Databases_history', { id => $params->{ history_id } });
        redirect '/';
    }

    my $database;

    if ( $params->{ database_id } ){
        $database = database->quick_select('Databases', { user => session->{data}->{user}->{id}, id => $params->{ database_id } } );
        session normal_database => 1;
    }
    elsif ( $params->{ history_id } ){
        $database = database->quick_select('Databases_history', { user => session->{data}->{user}->{id}, id => $params->{ history_id } } );
        session history_database => 1;
    }

    warn Dumper $database;
    session conversion_database => $database;
    warn Dumper session;

    my $utils = mongify::Utils->new( { database => $database , user_id => session->{data}->{user}->{id} } );

    my $config_file = $utils->generate_config_file( $database );
    my $filename = $utils->write_config_file();
    warn Dumper $filename;

    my $output = qx("mongify check $filename");

    warn Dumper $output;

    my $translation_filename = "database_translation_".session->{data}->{user}->{id}.".rb";
    $output = qx("mongify translation $filename > $translation_filename");

    session config_filename => $filename;
    session translation_filename => $translation_filename;

    warn Dumper $config_file;

    template 'Mongify 1.0 Config File', { config_file => $config_file };
};

post '/translation' => sub {
    my $params = request->params;
    warn Dumper $params;
    
    my $config_filename = session->{data}->{config_filename};
    my $translation_filename = session->{data}->{translation_filename};

    warn Dumper $config_filename, $translation_filename, "FILES@!#%";

    my $output = qx("mongify process $config_filename $translation_filename");
    my $exit_code = $? >> 8;

    warn Dumper $output, $exit_code, "OUTPUT#@*&^";

    if ( $exit_code == 0 && session->{data}->{normal_database} ) {
        database->quick_insert('Databases_history', { sql_adapter => session->{data}->{conversion_database}->{sql_adapter}, sql_host => session->{data}->{conversion_database}->{sql_host}, sql_username => session->{data}->{conversion_database}->{sql_username}, sql_password => session->{data}->{conversion_database}->{sql_password}, sql_database => session->{data}->{conversion_database}->{sql_database}, mongo_host => session->{data}->{conversion_database}->{mongo_host}, mongo_database => session->{data}->{conversion_database}->{mongo_database}, user => session->{data}->{user}->{id} });
        database->quick_delete('Databases', { id => session->{data}->{conversion_database}->{id} });
        template 'Mongify 1.0 Done';
    }
    else {
        template 'Mongify 1.0 Done', { output => $output };
    }

};

true;
