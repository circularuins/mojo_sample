use Mojolicious::Lite;

use File::Basename 'basename';
use File::Path 'mkpath';

use Data::Dumper;

# Image base URL
my $IMAGE_BASE = '/image_bbs/image';

# Directory to save image files
# (app is Mojolicious object. static is MojoX::Dispatcher::Static object)
my $IMAGE_DIR = app->home->rel_file( '/public' ) . $IMAGE_BASE;

# Create directory if not exists
unless ( -d $IMAGE_DIR ) {
    mkpath $IMAGE_DIR or die "Cannot create directory: $IMAGE_DIR";
}

# Display top page
get '/' => sub {
    my $self = shift;

    # Get file names(Only base name)
    my @images = map {basename($_)} glob( "$IMAGE_DIR/*" );
print Dumper @images;

    # sort by new order
    @images = sort {$b cmp $a} @images;
print Dumper @images;

    # Render
print Dumper $IMAGE_BASE;
    return $self->render( images => \@images, image_base => $IMAGE_BASE );

} => 'index';

# Upload image file
post '/upload' => sub {
    my $self = shift;

    # Uploaded image(Mojo::Upload object)
    my $image = $self->req->upload( 'image' );

    # Not upload
    unless ( $image ) {
        return $self->render(
            template => 'error',
            message => "Upload fail. File is not specified."
        );
    }

    # upload max size
    my $upload_max_size = 3 * 1024 * 1024;

    # Over max size
    if ( $image->size > $upload_max_size ) {
        return $self->render(
            template => 'error',
            message => "Upload fail. Image size is too large."
        );
    }

    # Check file type
    my $image_type = $image->headers->content_type;
    my %valid_types = map {$_ => 1} qw( image/gif image/jpeg image/png );

    # Content type is wrong
    unless ( $valid_types{$image_type} ) {
        return $self->render(
            template => 'error',
            message => "Upload fail. Content type is wrong."
        );
    }

    # Extention
    my $exts = {'image/gif' => 'gif', 'image/jpeg' => 'jpg', 'image/png' => 'png'};
    my $ext = $exts->{$image_type};

    # Image file
    my $image_file = "$IMAGE_DIR/" . create_filename() . ".$ext";

    # If file is exists, Retry creating filename
    while (-f $image_file) {
        $image_file = "$IMAGE_DIR/" . create_filename() . ".$ext";
    }

    # Save to file
    $image->move_to( $image_file );

    # Redirect to top page
    $self->redirect_to( 'index' );

} => 'upload';

sub create_filename {

    # Date and time
    my ( $sec, $min, $hour, $mday, $month, $year ) = localtime;
    $month = $month + 1;
    $year = $year + 1900;

    # Random number (0~99999)
    my $rand_num = int( rand 100000 );

    # Create file name from datatime and random number
    my $name = sprintf(
        "image_%04s%02s%02s%02s%02s%02s-%05s",
        $year,
        $month,
        $mday,
        $hour,
        $min,
        $sec,
        $rand_num
    );

    return $name;
}

app->start;

__DATA__

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

@@ index.html.ep
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;charset=UTF-8" >
    <title>Image BBS</title>
  </head>
  <body>
    <h1>Image BBS</h1>
    <form method="post" action="<%= url_for('upload') %>" enctype="multipart/form-data">
      <div>
        File name
        <input type="file" name="image" >
        <input type="submit" value="Upload" >
      </div>
    </form>
    <div>
      <% for my $image ( @$images ) { %>
            <div>
              <hr>
              <div>Image: <%= $image %></div>
              <div>
                <img src="<%= "image_base/$image" %>">
              </div>
            </div>
      <% } %>
    </div>
  </body>
</html>
