package Koha::Plugin::AllSaints::BooksNotReturned;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;
use Koha::DateUtils qw( output_pref dt_from_string );
use Koha::Database;

use Text::CSV::Slurp;

## Here we set our plugin version
#our $VERSION = "{VERSION}";
our $VERSION = "1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Books Not Returned',
    author => 'Stephen Gaito on behalf of All Saints CofE school',
    description =>
'This report lists the books currently check out.',
    date_authored   => '2023-10-03',
    date_updated    => '2023-10-03',
    minimum_version => '23.05.04.000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('output') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    return 1;
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'report-step1.tt' } );

    print $cgi->header();
    print $template->output();
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;

    my $output   = $cgi->param('output');

    # Create the query
    my $query = <<'END_STATEMENT';
SELECT
 categories.description AS className,
 CONCAT(firstname, ' ', surname) AS pupilName,
 GROUP_CONCAT(biblio.title) AS bookTitle,
 DATE_FORMAT(issuedate, '%Y %b %e') AS dateIssued,
 DATEDIFF(CURDATE(), issuedate) DIV 7 AS weeksOut,
 DATE_FORMAT(date_due, '%Y %b %e') AS dateDue,
 DATEDIFF(CURDATE(), date_due) AS daysOverdue
FROM borrowers
JOIN issues USING (borrowernumber)
JOIN items USING (itemnumber)
JOIN biblio USING (biblionumber)
JOIN categories USING (categorycode)
GROUP BY categorycode,date_due,firstname,surname
END_STATEMENT

    # Prepare and execute the query
    my $sth = $dbh->prepare($query);
    $sth->execute();

    my @booksOut = ();
    while (my %aRow = $sth->fetchrow_hashref()) {
      push(@booksOut, \%aRow);
    }

    my $filename;
    if ( $output eq "csv" ) {
        print $cgi->header( -attachment => 'booksOut.csv' );
        print Text::CSV::Slurp->create( input => \@booksOut );
    } elsif ( $output eq "pdf") {
      # don't do anything at the moment...
    } else {
        print $cgi->header();
        $filename = 'report-step2-html.tt';

        my $template = $self->get_template( { file => $filename } );

        $template->param(
            results_loop => \@booksOut,
        );

        print $template->output();
    }

}

1;
