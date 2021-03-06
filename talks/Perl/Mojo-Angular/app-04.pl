#!/usr/bin/env perl

use Mojolicious::Lite;

use Mango;
my $mango = Mango->new;
$mango->default_db( 'jade_kingdom' );

get '/' => sub {
    my ( $self ) = @_;
    $self->render( 'index' );
};

get '/api/user' => sub {
    my ( $self ) = @_;
    $self->render(
        json => $mango->db->collection('user')->find->all,
    );
};

app->start;
__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
    <body>
        <table>
            <tr>
                <th>E-mail</th>
                <th>Created</th>
                <th>Last Seen</th>
                <th>Can Play</th>
            </tr>
            <tr>
                <td></td>
                <td></td>
                <td></td>
                <td></td>
            </tr>
        </table>
        <script src="/js/angular.min.js"></script>
    </body>
</html>
