package AbraNotes;
use base 'CGI::Application';
use CGI::Application::Plugin::TT;

use strict;

# we need a database connection
# later might experiment with DBI::Class
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);

1;

sub setup {
    my $self = shift;

    $self->start_mode('show_block');
    $self->tmpl_path('/w/abra2/templates/');
    $self->run_modes([qw/ 
	get_notes_json
	show_block
	show_pending_notes
	add_note
	del_note
	update_note
    /]);

    $self->tt_include_path('/w/abra2/template');

    $self->dbh_config('dbi:mysql:abra','abra','meoow');
}

sub add_note {
    my $self = shift;
    my $q = $self->cgiapp_get_query;
}

sub show_block {
    my $self = shift;

}

sub del_note {
    my $self = shift;
}

sub update_note {
    my $self = shift;
}

sub show_pending_notes {
    my $self = shift;
}

sub get_notes_json {
    my $self = shift;
}

sub teardown {
   my $self = shift;
 
   $self->dbh->disconnect();
}


