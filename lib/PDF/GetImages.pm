package PDF::GetImages;
use strict;
use File::Which 'which';
use Carp;
#use Cwd;
require Exporter;
use vars qw(@EXPORT_OK @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(pdfimages);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;



$PDF::GetImages::DEBUG =0;
sub DEBUG : lvalue { $PDF::GetImages::DEBUG }




sub pdfimages {
	my $pdf = shift;
	-f $pdf and $pdf=~/\.pdf$/i or warn(__PACKAGE__."::pdfimages() [$pdf] not pdf?") and return [];

	my $filename_only = $pdf; 
   $filename_only=~s/\.pdf$|^.+\/+//gi or die(__PACKAGE__."::pdfimages() mismatch");# should never happen, we just tested for this attop

#	my $cwd= cwd();
	#defined $cwd or warn(__PACKAGE__."::pdfimages() cannot get cwd() value, cannot continue.") and return [];
	
	my $abs_loc = $pdf; $abs_loc=~s/\/*[^\/]+$// or die(__PACKAGE__."::pdfimages(), cant get abs loc");
	defined $abs_loc and $abs_loc or warn("abs location for $pdf resolves to nothing? cannot continue.") and return [];
   
	
	my $bin = which('pdfimages') or die( __PACKAGE__."::pdfimages() will not work, is pdfimages (xpdf) installed?");

	chdir($abs_loc) or warn(__PACKAGE__."::pdfimages() cannot chdir into $abs_loc.") and return [];	
   my @args=($bin, $pdf,$filename_only);
   print STDERR " args @args\n" if DEBUG;
   
	system(@args) == 0
		or die("system [@args] bad.. $?");		
	opendir(DIR, $abs_loc) or die("cannot open dir $abs_loc");
	my @pagefiles = map { $_ = "$abs_loc/$_" } sort grep { /$filename_only.+\.p.m$/i } readdir DIR;
	closedir DIR;
#	chdir($cwd); # go back to same place we started

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

If this is not a pdf, the file does not exist, or no images 
are extracted, warns and returns empty array ref []

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
