package Image::OCR::Tesseract;
use strict;
use File::Which 'which';
use Carp;
use Cwd;
#use File::Slurp;
require Exporter;
use vars qw(@EXPORT_OK @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_ocr _tesseract);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)/g;

$Image::OCR::Tesseract::DEBUG= 0;
sub DEBUG : lvalue { $Image::OCR::Tesseract::DEBUG }








sub get_ocr {
	my ($abs_image,$abs_tmp )= @_;
	-f $abs_image or croak(__PACKAGE__."::get_ocr() [$abs_image] is not a file");

	$abs_tmp||='/tmp';

	my $content;

	unless( $abs_image=~/\.tif{1,2}$/i ){ # must be tiff for tesseract

		my $abs_tif = $abs_tmp.'/.tesseract_temp_'.time().(int rand 2000).'.tif';		
		my $convert = which('convert') or die("is ImageMagick properly installed on this system? missing convert?");		
		my @args = ($convert, $abs_image, '-compress','none','-colorspace','rgb','-contrast',$abs_tif);
	   
   
		system(@args) == 0 
				or warn(__PACKAGE__."::get_ocr(), imagemagick convert problem? @args, $?") and return;				
				
		$content = _tesseract($abs_tif); defined $content or $content = '';
		print STDERR "temp tif: $abs_tif\n" if DEBUG;		
		unlink $abs_tif unless DEBUG;
		
		return $content;
	}

	$content = _tesseract($abs_image);	
	return $content;
}



sub _tesseract {
	my $abs_image = shift;
	#-f $abs_image or die("$abs_image not image");

	$Image::OCR::Tesseract::bin ||= which('tesseract') or die('missing tesseract?');

	#my @args = ($tesseract,$abs_image,$abs_image);

   
   my $tesseract = $Image::OCR::Tesseract::bin;
	system("$tesseract $abs_image $abs_image 2>/dev/null");
	#	or warn("call to tesseract ocr failed, system [@args] : $?") and return;

      
	
	my $txt = "$abs_image.txt";
	print STDERR "text saved as '$abs_image.txt'\n" if DEBUG;
	my $content;
	if (-f $txt){
		#$content = File::Slurp::slurp($txt);
      $content = _slurp($txt);
		unlink($txt) unless DEBUG;
	}

	else {
		$content = 0;
		warn("tesseract did not output? nothing inside [$abs_image]?");		
	}
	return $content;
}



sub _slurp {
   my $abs = shift;
   open(FILE,'<', $abs) or die($!);
   local $/;
   my $txt = <FILE>;
   close FILE;
   return $txt;
   
}  

1;

__END__

=pod

=head1 NAME

Image::OCR::Tesseract - read an image with tesseract and get output

=head1 SYNOPSIS

	use Image::OCR::Tesseract 'get_ocr';

	my $image = './hi.jpg';

	my $text = get_ocr($image);

=head1 DESCRIPTION

This is a simple wrapper for tesseract.

Tesseract expects a tiff file, get_ocr() will convert to a temporary tiff if your file is not a tiff file
that way you don't have to worry about your image format for ocr.

Tesseract spits out a text file- get_ocr() will erase that and return you the output.

This is part of the PDF::OCR package.

=head1 get_ocr()

Argument is abs path to image file. Optional argument is abs path to temp dir, (if you can't write to /tmp) 
default is /tmp
Returns text content as read by tesseract.
Does not clean up after itself if DEBUG is on

warns if no output

=head1 _tesseract()

Argument is abs path to tif file. Will return text output. 
If none inside or tesseract fails, returns empty string.
If tesseract fails, warns.

=head1 SEE ALSO

tesseract

gocr

=head1 DEBUG

Set the debug flag on:

	$Image::OCR::Tesseract::DEBUG = 1;

A temporary file is created, if DEBUG is on, the file is not deleted, the file path is printed to STDERR.

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
