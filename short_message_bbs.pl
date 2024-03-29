#!~/.plenv/shims perl

use Mojolicious::Lite;
use utf8;
use Encode qw/encode decode/;

# Data file (app is Mojolicious object. home is Mojo::Home object)
my $data_file = app->home->rel_file( 'bbs_data.txt');

# Create entry
post '/create' => sub {
    my $self = shift; # ($self is Mojolicious::Controller object)

    # Form data (This data is Already decoded)
    my $title = $self->param( 'title' );
    my $message = $self->param( 'message' );

    # Display error page if title is not exist.
    return $self->render( template => 'error', message => 'Please input title' ) unless $title;

    # Display error page if message is not exist.
    return $self->render( template => 'error', message => 'Please input message' ) unless $message;

    # Chech title length
    return $self->render( template => 'error', message => 'Title is too long' ) if length $title > 30;

    # Chech message length
    return $self->render( template => 'error', message => 'Message is too long' ) if length $message > 100;

    # Data and time
    my ( $sec, $min, $hour, $day, $month, $year ) = localtime;
    $month = $month + 1;
    $year = $year + 1900;

    # Format date (yyyy/mm/dd hh:MM:ss)
    my $datetime = sprintf( "%04s/%02s/%02s %02s:%02s:%02s", $year, $month, $hour, $min, $sec );

    # Delete line breaks
    $message =~ s/\x0D\x0A|\x0D|\x0A//g;

    # Writing data
    my $record = join( "\t", $datetime, $title, $message ) . "\n";

    # File open to write
    open my $data_fh, ">>", $data_file or die "Cannot open $data_file: $!";

    # Encode
    $record = encode( 'UTF-8', $record );

    # Write
    print $data_fh $record;

    # Close
    close $data_fh;

    # Redirect
    $self->redirect_to( 'index' );

} => 'create';

get '/' => sub {
    my $self = shift;

    # Open data file (Create file if not exist)
    my $mode = -f $data_file ? '<' : '+>';
    open my $data_fh, $mode, $data_file or die "Cannot open $data_file: $!";

    # Read data
    my $entry_infos = [];
    while ( my $line = <$data_fh> ) {
        $line = decode( 'UTF-8', $line );

        chomp $line;
        my @record = split /\t/, $line;

        my $entry_info = {};
        $entry_info->{datetime} = $record[0];
        $entry_info->{title} = $record[1];
        $entry_info->{message} = $record[2];

        push @$entry_infos, $entry_info;
    }

    # Close
    close $data_fh;

    # Reverse data order
    @$entry_infos = reverse @$entry_infos;

    # Render index page
    $self->render( entry_infos => $entry_infos );

} => 'index';

app->start;


__DATA__

@@ index.html.ep
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" >
    <title>Short Message BBS</title>
  </head>
  <body>
    <h1>Short Message BBS</h1>
    <form method="post" action="<%= url_for( 'create' ) %>">
      <div>
        Title
        <input type="text" name="title" >
      </div>
      <div>Message</div>
      <div>
        <textarea name="message" cols="50" rows="10" ></textarea>
      </div>
      <div>
        <input type="submit" value="Post" >
      </div>
    </form>
    <div>
  <% for my $entry_info( @$entry_infos ) { %>
      <div>
        <hr>
        <div>Title: <%= $entry_info->{title} %> (<%= $entry_info->{datetime} %>)</div>
        <div>Message</div>
        <div><%= $entry_info->{message} %></div>
      </div>
  <% } %>
    </div>
  </body>
</html>


@@ error.html.ep
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" >
    <title>Error</title>
  </head>
  <body>
    <%= $message %>
  </body>
</html>
