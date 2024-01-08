package Koha::Plugin::AllSaints::BooksCheckedOut;

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
use Koha::Logger;

use Text::CSV::Slurp;
use PDF::API2;

## Here we set our plugin version
#our $VERSION = "{VERSION}";
our $VERSION = "1.0";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Books checked out',
    author => 'Stephen Gaito on behalf of All Saints CofE school',
    description =>
'This report lists the books currently check out.',
    date_authored   => '2023-10-03',
    date_updated    => '2024-01-07',
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

    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    $year  = 1900 + $year;
    my $month = $mon + 1;
    my $csvFileName = sprintf("booksCheckedOut_%d_%02d_%02d.csv", $year, $month, $mday);
    my $pdfFileName = sprintf("booksCheckedOut_%d_%02d_%02d.pdf", $year, $month, $mday);
    my $pdfToday    = sprintf("%d %s %d", $year, $months[$mon], $mday);
    # Create the query
    my $query = <<'END_STATEMENT';
SELECT
 categories.description AS className,
 CONCAT(firstname, ' ', surname) AS pupilName,
 GROUP_CONCAT(biblio.title) AS bookTitle,
 DATE_FORMAT(issuedate, '%Y %b %e') AS dateIssued,
 DATEDIFF(CURDATE(), issuedate) DIV 7 AS weeksOut,
 DATE_FORMAT(date_due, '%Y %b %e') AS dateDue,
 DATEDIFF(CURDATE(), date_due) AS daysOverdue,
 borrowernumber AS borrowerNumber,
 biblionumber AS biblioNumber
FROM borrowers
JOIN issues USING (borrowernumber)
JOIN items USING (itemnumber)
JOIN biblio USING (biblionumber)
JOIN categories USING (categorycode)
GROUP BY categorycode,date_due,firstname,surname
END_STATEMENT

		my $log = Koha::Logger->get();
		#$log->warn("Before prepare and execute\n");

    # Prepare and execute the query
    my $sth = $dbh->prepare($query);
    $sth->execute();

		#$log->warn("After prepare and execute\n");

    my @booksOut = ();
    while (my $aRow = $sth->fetchrow_hashref()) {
      #$log->warn("Fetched a row\n");
      push(@booksOut, $aRow);
    }
		#$log->warn("Fetched everything\n");

    my $filename;
    if ( $output eq "csv" ) {
      print $cgi->header( -attachment => $csvFileName );
      print Text::CSV::Slurp->create(
        input => \@booksOut,
        field_order => [
        	'className', 'pupilName', 'bookTitle',
         	'dateIssued', 'weeksOut', 'dateDue', 'daysOverdue'
        ]
      );
    } elsif ( $output eq "pdf") {
      print $cgi->header( -attachment => $pdfFileName );
      ########################################################################
      # PDF Configuration

      my $numRowsPerPage  = 35;
      my $numRowsPerGroup = 5;

      # PDF configuration (in pixels)
      #   setting for A4 landscape
      my $pdfWidth       = 842;
      my $pdfHeight      = 595;
      my $pdfTopMargin   = 570;
      my $pdfLeftMargin  = 25;
      my $pdfSmallLine   = 10;
      my $pdfHRuleLength = 800;

      my $pdfOverdue     = '#FF0000';
      my $pdfFont        = 'Helvetica-Bold';

      #                       class name title issue weeks due
      my @tableWidths    = qw(100   200  300   100   100   100);

      my @columnNames = (
        'className', 'pupilName', 'bookTitle',
        'dateIssued', 'weeksOut', 'dateDue'
      );

      my @columnHeaders = (
        'Class Name', 'Pupil Name', 'Book Title',
        'Date Issued', 'Weeks Out', 'Date Due'
      );

      ########################################################################
      # PDF local subroutines

      local *newLine = sub {
        my $text = shift(@_);
        #my $pdfLeftMargin = shift(@_);
        $text->crlf();
        my ($x, $y) = $text->position();
        $text->position($pdfLeftMargin-$x, 0);
      };

      local *addSmallLine = sub {
        my ($text, $scale) = @_;
        if (not defined $scale) { $scale = 1.0 }
        $text->position(0, -$pdfSmallLine*$scale);
      };

      local *addHRule = sub {
        my ($text, $graphics, $lineColor) = @_;
        if (not defined $lineColor) { $lineColor = 'black' }
        my ($x, $y) = $text->position();
        $graphics->strokecolor($lineColor);
        $graphics->move($x,$y+9);
        $graphics->hline($pdfHRuleLength);
        $graphics->stroke();
      };

      ########################################################################
      # Steup the PDF
      my $pdf = PDF::API2->new();

      # Add a built-in font to the PDF
      my $font = $pdf->font($pdfFont);

      ########################################################################
      # Walk through the query results

      my $page;
      my $text;
      my $graphics;

      my $lastClass    = "";
      my $curClass     = "unknown";
      my $classPageNum = 1;
      my $curRow       = 0;

      for my $row (0..$#booksOut)  {
        #p $booksOut[$row];
        $curClass = $booksOut[$row]->{className};
        if (($lastClass ne $curClass) || ($numRowsPerPage <= $curRow)) {
          # Add a blank page
          $page = $pdf->page();

          # Set the page size
          $page->size([ $pdfWidth, $pdfHeight ]);

          # Get the graphics object
          $graphics = $page->graphics();

          # Get the text object and set the font and initial position
          $text = $page->text();
          $text->font($font, 12);
          $text->position($pdfLeftMargin, $pdfTopMargin);

          # Add the class name
          $classPageNum = 1 if ($lastClass ne $curClass);
          $text->text("$curClass ");
          $text->fill_color('#808080');
          $text->text("($pdfToday ; page $classPageNum)");
          $text->fill_color('#000000');
          newLine($text);
          addSmallLine($text);

          $curRow = 0;
          $lastClass = $curClass;

          # Add the header
          foreach my $colno (1..$#columnHeaders) {
            $text->text($columnHeaders[$colno]);
            $text->position($tableWidths[$colno], 0);
          }
          newLine($text);
          addHRule($text, $graphics);
          addSmallLine($text, 0.5);
          $classPageNum++;
        }

        # Add a single row of information
        foreach my $colno (1..$#columnNames) {
          if ( ($colno == 5) && (0 < $booksOut[$row]{daysOverdue})) {
            $text->fill_color('#FF0000');
          }else{
            $text->fill_color('#000000');
          }
          $text->text($booksOut[$row]{$columnNames[$colno]});
          $text->position($tableWidths[$colno], 0);
        }
        newLine($text);
        $curRow++;
        if ($curRow % $numRowsPerGroup == 0) {
          addHRule($text, $graphics, 'grey');
          addSmallLine($text, 0.5)
        }
      }

      ########################################################################
      # Save the PDF
      print $pdf->to_string();
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
