#!/usr/bin/env perl
use Mojolicious::Lite;

# Documentation browser under "/perldoc"
#[plugin 'PODRenderer';

under '/html';

get '/(*path)/create' => sub {
  my $self = shift;
  $self->render('index');
};

get '/(*path)' => sub {
  my $self = shift;
  $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious!
<%= stash 'path' %>
