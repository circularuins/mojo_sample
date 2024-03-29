#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::IOLoop;

# Documentation browser under "/perldoc"
#plugin 'PODRenderer';

my $clients = {};
my $loop = Mojo::IOLoop->singleton;

websocket '/' => sub {
    my $self = shift;

    # Client id
    my $cid = "$self";

    # Controller
    my $controller = $self;

    # Send date and time
    my $datetime = localtime;
    $self->send($datetime);

    # Recieve message
    $self->on('message' => sub {
                  my ($self, $message) = @_;

                  # Start clock
                  if ($message eq 'Start') {

                      # Shortcut
                      return if $clients->{$cid}{running};

                      # Start
                      $clients->{$cid}{running} = 1;

                      # Subroutine for sending date and time
                      my $send_datetime;
                      $send_datetime = sub {

                          # Send date and time
                          my $datetime = localtime;
                          $controller->send($datetime);

                          # Timer
                          $loop->timer(1, $send_datetime) if $clients->{$cid}{running};
                      };

                      # Send
                      $send_datetime->();
                  }

                  # Stop clock
                  else { $clients->{$cid}{running} = 0 }
              });

    # on_finish
    $self->on('finish' => sub {
                  # Remove client
                  delete $clients->{$cid};
              });
};

get '/' => 'index';

app->start;
__DATA__

@@ index.html.ep
% my $url = $self->req->url->to_abs->scheme( $self->req->is_secure ? 'wss' : 'ws' )->path( '/' );
<!doctype html>
<html>
  <head>
    <title>Mojo websocket Demo</title>

    <script type="text/javascript">
      // only load the flash fallback when needed
    if ( ! ( 'WebSocket' in window ) ) {
        document.write([
            '<scr'+'ipt type="text/javascript" src="web-socket-js/swfobject.js"></scr'+'ipt>',
            '<scr'+'ipt type="text/javascript" src="web-socket-js/FABridge.js"></scr'+'ipt>',
            '<scr'+'ipt type="text/javascript" src="web-socket-js/web_socket.js"></scr'+'ipt>'
        ].join(''));
    }
    </script>
    <script type="text/javascript">
    if ( WebSocket.__initialize ) {
        // Set URL of your WebSocketMain.swf here:
        WebSocket.__swfLocation = 'web-socket-js/WebSocketMain.swf';
    }

    // example copied from web-socket-js/sample.html
    var ws, input, clock;

    function init() {

        // Connect to Web Socket.
        ws = new WebSocket('<%= $url %>');

        // Receive message
        ws.onmessage = function(e) {
            // Update clock
            clock = document.getElementById('clock');
            clock.innerHTML = e.data;
        };
    }

    function onClockStart() {
        // Start clock
        ws.send('Start');
    }

    function onClockStop() {
        // Stop clock
        ws.send('Stop');
    }

    window.onload = init;
    </script>
  </head>
  <body>
    <span id="clock"></span>
    <button onclick="onClockStart(); return false;">Start</button>
    <button onclick="onClockStop(); return false;">Stop</button>
  </body>
</html>
