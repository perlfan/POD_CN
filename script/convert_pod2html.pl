use strict;
use warnings;
use Data::Dumper;
use Pod::Html;
use FileHandle;
use Getopt::Long;
use Carp;
use File::Basename;
use File::Spec;
use Cwd qw(abs_path);

my $module_list;

GetOptions( "m:s" => \$module_list );

if ( !$module_list ) {
    Carp::croak(
        "you must defined a module list like \n",
        "$0 -m File::Spec,File::Basename\n"
    );
}

my $changed_pre = q{<pre class="brush: perl; gutter: true">};
my $pod_path    = abs_path( dirname(__FILE__) ) . "/../pod";
my $html_path   = abs_path( dirname(__FILE__) ) . "/../html";

for my $module_name ( split( ",", $module_list ) ) {
    $module_name =~ s{::}{-}g;
    my $per_pod_file = File::Spec->catfile( $pod_path, $module_name );

    if ( !-e $per_pod_file ) {
        Carp::croak("this module ${module_name}'s pod is not exists\n");
    }

    # init file handle
    my $readpod_r = new FileHandle($per_pod_file);
    my $cpan_html_file = File::Spec->catfile( $html_path, $module_name.".html" );
    my $zh_pod_file  = File::Spec->catfile( $pod_path, $module_name . ".zh" );
    my $wp_html_file = $cpan_html_file . "_wp.html";
    my $zh_pod_w     = new FileHandle( ">" . $zh_pod_file )
      or Carp::croak("creat zh pod file failed");

  READ_TRANSFERED_FILE:
    while ( my $line = <$readpod_r> ) {
        #chomp($line);

        if ( $line =~ m/^=head1/xis ) {
            while ( $line = <$readpod_r> ) {
                if ( $line =~ m/^zh:(.*) # match zh line/xis ) {
                    print $zh_pod_w $1; 
                }
                elsif ( $line =~ m{^(?:\t|\s) # match code block}xis ) {
                    print $zh_pod_w $line;
                }
            }
        }
    }
    close($readpod_r);
    close($zh_pod_w);

    if ( -s $zh_pod_file > 0 ) {
        pod2html( 
            "--infile="  . $zh_pod_file , 
            "--outfile=" . $cpan_html_file,
            "--title="   . $module_name,
        );

        # substitute for wp format html document
        my $wp_pre      = q{<pre class="brush: perl; gutter: true">};
        my $cpan_html_r = new FileHandle($cpan_html_file)
          or Carp::croak("open file failed $@");
        my $wp_html_w = new FileHandle( ">" . $wp_html_file )
          or Carp::croak("open wp html failed\n");

        do {
            local $/ = undef;
            my $content = <$cpan_html_r>;
            $content =~ s{<span.*?>}{}sg;
            $content =~ s{</span>}{}sg;
            $content =~ s{</pre>[^<]*<pre>}{}sg;
            $content =~ s{<pre>}{$changed_pre}sg;
            print $wp_html_w $content,"\n";
        };
        close($wp_html_w);
        close($cpan_html_r);

        print "-------------------------", "\n";
        print "All Convert are finished\n";
        print "Convert Output File are:",        "\n";
        print "cpan_html_file: $cpan_html_file", "\n";
        print "wp_html_file  : $wp_html_file",   "\n";
        print "zh_pod_file   : $zh_pod_file",    "\n";
    }
}

=pod 
my $changed_pre = q{<pre class="brush: perl; gutter: true">};  
my $content =do { open FH,$file;local $/;<FH> };
$content =~ s{<span.*?>}{}sg;
$content =~ s{</span>}{}sg;
$content =~ s{</pre>[^<]*<pre>}{}sg;
$content =~ s{<pre>}{$changed_pre}sg;

print $content;
=cut

