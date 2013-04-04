#!~/.plenv/shims perl

use Mojolicious::Lite;
use utf8;
use Encode qw/encode decode/;
use DateTime;

my %answer = ( 0 => "ババアッ！",
               1 => "ママー",
               2 => "まましゃんす？",
               3 => "オトコーーー",
               4 => "ぅおとぅくぅおいぃっす！",
               5 => "ぼく、いぬじゃないよ？",
               6 => "ぼく、いぬだよ？",
               7 => "ぼく、ひがいしゃだよ？",
               8 => "だまればばあ！",
               9 => "奈良のおとうさん、おかあさん、おにいさん、おねえさん、おじいさん、おばあさん",
               10 => "奈良のおとうさん、おかあさん、おにいさん、おねえさん、おじいさん、おばあさん、、、、お、お、お、おぅとくぅおーーーー！",
               11 => "奈良のおとうさん、おかあさん、おにいさん、おねえさん、おじいさん、おばあさん、、、、お、お、お、ママー！",
               12 => "ぼく、いぬなの？",
               13 => "おとこって……ゲスだよ！",
               14 => "ママやらせろっ",
               15 => "おとこやらせろっ",
               16 => "",
           );

# Data file (app is Mojolicious object. home is Mojo::Home object)
my $data_file = app->home->rel_file( 'bbs_data2.txt');

# Create entry
post '/create' => sub {
    my $self = shift; # ($self is Mojolicious::Controller object)

    # Form data (This data is Already decoded)
    my $message = $self->param( 'message' );

    # Random answer
    my $random_answer;
    my $rand = int(rand scalar(keys(%answer)));
    if ($rand == 16) {
        $random_answer = $message . "ってなに？";
    }
    else {
        $random_answer = $answer{$rand};
    }

    # Display error page if message is not exist.
    return $self->render( template => 'error', message => 'Please input message' ) unless $message;

    # Chech message length
    return $self->render( template => 'error', message => 'Message is too long' ) if length $message > 100;

    # Data and time
    my $dt = DateTime->now( time_zone => 'Asia/Tokyo' );

    # Format date (yyyy/mm/dd hh:MM:ss)
#    my $datetime = sprintf( "%04s/%02s/%02s %02s:%02s:%02s", $year, $month, $hour, $min, $sec );
    my $datetime = $dt->strftime('%Y/%m/%d %H:%M');

    # Delete line breaks
    $message =~ s/\x0D\x0A|\x0D|\x0A//g;

    # Writing data
    my $record = join( "\t", $datetime, $message, $random_answer ) . "\n";

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
        $entry_info->{message} = $record[1];
        $entry_info->{answer} = $record[2];

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
    <title>楽太郎</title>
  </head>
  <body>
    <h1>楽太郎</h1>
    <form method="post" action="<%= url_for( 'create' ) %>">
      <div>Message</div>
      <div>
        <textarea name="message" cols="50" rows="2" ></textarea>
      </div>
      <div>
        <input type="submit" value="話す" >
      </div>
    </form>
    <div>
  <% for my $entry_info( @$entry_infos ) { %>
      <div>
        <hr>
        <div>Message</div>
        <div><%= $entry_info->{message} %></div>
        <div><img src="image/1.jpg" alt="ら"></div>
        <div><%= $entry_info->{answer} %></div>
        <div>(<%= $entry_info->{datetime} %>)</div>
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
