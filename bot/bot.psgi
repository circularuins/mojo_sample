use Plack::App::WrapCGI;
use Plack::Builder;

my $app = Plack::App::WrapCGI->new( script => '/home/ubuntu11/study/Perl/mojo/bot/raku-ver1.pl' )->to_app;
builder {
    enable "Plack::Middleware::Static",
        path => qr{^/image/},
        root => '/home/ubuntu11/study/Perl/mojo/bot/';
    $app;
};
