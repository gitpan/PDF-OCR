package PDF::GetImages;
use strict;
use File::Which 'which';
use Carp;
use Cwd;
require Exporter;
use vars qw(@EXPORT_OK @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(pdfimages);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;


sub pdfimages {
	my $pdf = shift;
	-f $pdf and $pdf=~/\.pdf$/i or croak(__PACKAGE__."::pdfimages() [$pdf] not pdf?");

	my $filename_only = $pdf; $filename_only=~s/\.pdf$|^.+\/+//gi or die(__PACKAGE__."::pdfimages() mismatch");

	my $cwd= cwd();
	
	my $abs_loc = $pdf; $abs_loc=~s/\/*[^\/]+$// or die(__PACKAGE__."::pdfimages(), cant get abs loc");

	
	my $bin = which('pdfimages'); $bin or die(	__PACKAGE__."::pdfimages() will not work, is pdfimages (xpdf) installed?");

	chdir $abs_loc;	
	system($bin, $pdf,$filename_only) == 0
		or die("$?");		
	opendir(DIR, $abs_loc) or die();
	my @pagefiles = map { $_ = "$abs_loc/$_" } sort grep { /$filename_only.+\.p.m$/i } readdir DIR;
	closedir DIR;
	chdir $cwd; # go back to same place we started

	unless(scalar @pagefiles){
		carp(__PACKAGE__."::pdfimages() no output from pdfimages for [$pdf]? [$abs_loc]");
		return [];
	}
	
	return \@pagefiles;
}



1;

__END__

=pod

=head1 NAME

PDF::GetImages - get images from pdf document

=head1 SYNOPSIS

	use PDF::GetImages 'pdfimages';

	my $images = pdfimages('/abs/path/tofile.pdf');

=head1 DESCRIPTION

Get images out of a pdf document. This is a perl interface to pdfimages.

=head1 pdfimages()

argument is abs path to pdf doc
optional argument is a dir to which to send images extracted
returns abs paths to images extracted
images are extracted to same dir pdf is in

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2007 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
