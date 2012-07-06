use strict;
use warnings;
use Data::Dumper;
use FileHandle;
use LWP::UserAgent;
use File::Basename;
use File::Spec;
use Getopt::Long;
use Carp;
use HTTP::Request;
use Encode qw(decode_utf8);

my $module_list;

GetOptions( "m:s" => \$module_list );

if( !$module_list ){
    die "please input cpan module name like File::Spec\n";
}

my $perldoc_uri = 'http://search.cpan.org/perldoc';
my $pod_src     = "http://cpansearch.perl.org/src/";
my $ua          = new LWP::UserAgent;
$ua->timeout(120);

foreach my $module_name ( split( ',', $module_list ) ) {
    my $res = $ua->simple_request(
        new HTTP::Request( GET => $perldoc_uri . "?" . $module_name ) );

    if ( $res->code eq '302' ) {
        my $location = $res->header('location');
        $location =~ s{^/~([^/]+)}{$pod_src.uc($1)}e;
        my $pod_res = $ua->get($location);
        if ( $pod_res->is_success ) {
            my $pod = decode_utf8( $pod_res->content() );

            my $source_dir = dirname(__FILE__) . "/../pod";
            my $file_name;
            ( $file_name = $module_name ) =~ s{::}{-}g;
            my $source_file = File::Spec->catfile( $source_dir, $file_name );
            my $source_w = new FileHandle(">$source_file") or Carp::croak($@);
            print $source_w $pod;
            print "---------------------------", "\n";
            print "Download $module_name pod file success in $source_file\n";
            print "Now you can transfer this $module_name pod", "\n";
            print "---------------------------",                "\n";
        }
        else {
            Carp::croak(
                "download pod failed with $module_list\n"
            );
        }
    }
}

exit 0;
