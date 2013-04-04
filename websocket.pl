#!/usr/bin/env perl
use utf8;
use Mojolicious::Lite;
use DateTime;
use Mojo::JSON;

get '/' => 'index';

my $clients = {};

websocket '/echo' => sub {
        my $self = shift;

        app->log->debug(sprintf 'Client connected: %s', $self->tx);
        my $id = sprintf "%s", $self->tx;
        $clients->{$id} = $self->tx;

        $self->receive_message(
            sub {
                my ($self, $msg) = @_;

                my $json = Mojo::JSON->new;
                my $dt   = DateTime->now( time_zone => 'Asia/Tokyo');

                for (keys %$clients) {
                    $clients->{$_}->send_message(
                        $json->encode({
                            hms  => $dt->hms,
                            text => $msg,
                        })
                    );
                }
            }
        );

        $self->finished(
            sub {
                app->log->debug('Client disconnected');
                delete $clients->{$id};
            }
        );
    };

app->start;

__DATA__
@@ index.html.ep
<html>
  <head>
    <title>WebSocket Client</title>
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" ></script>
    <script type="text/javascript" src="/js/ws.js"></script>
    <style type="text/css">
      textarea {
      width: 40em;
      height:10em;
      }
    </style>
  </head>
  <body>

    <h1>Mojolicious + WebSocket</h1>

    <p><input type="text" id="msg" /></p>
    <textarea id="log" readonly></textarea>

  </body>
</html>
