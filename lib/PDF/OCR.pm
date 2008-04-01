package PDF::OCR;
use strict;
use vars qw($VERSION $DEBUG);
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;

sub DEBUG : lvalue { $DEBUG }

sub new {
	my($class, $arg) = @_;
	$arg or croak("missing argument to constructor");	
	my $self = {};

   
   require Cwd;
	my $abs = Cwd::abs_path($arg) 
      or croak("[$arg] not resolving with Cwd::abs_path()");

	$abs=~/\.pdf$/i 
      or croak("[$arg] cant match pdf ext in filename");

	-f $abs 
      or croak("[$abs] is not file.");

   $self->{abs_pdf} = $abs;
   
   bless $self,$class;
   return $self;
   

	#my $tmpdir = '/tmp';
	#my $tmpfilename = 'ocrtmp_'.time().(int rand 8000);
	#$self->{abs_tmp} = "$tmpdir/$tmpfilename.pdf";
	#bless $self, $class;

	#File::Copy::cp($abs, $self->abs_tmp);	
	#return $self;
}

sub abs_pdf {
   my $self = shift;
   return $self->{abs_pdf};
}

sub abs_tmp {
	my $self= shift;
	return $self->{abs_tmp};
}


sub abs_images {
	my $self = shift;

	unless( defined $self->{abs_images}){		
      require PDF::GetImages;
		my $images = PDF::GetImages::pdfimages($self->abs_pdf);
      unless( scalar @$images ){
         warn("no images in ".$self->abs_pdf);
         $self->{abs_images} = [];
         return [];
      }
      $self->{abs_images} = $images;
	}
	
	return $self->{abs_images};
}

sub abs_images_count {
   my $self = shift;
   return scalar @{$self->abs_images};
}




sub get_ocr {
	my ($self,$abs)= @_;
	
	if(defined $abs){
		return $self->_get_ocr($abs);
	}

	my $ocr = join( "\f", @{$self->get_ocr_arrayref} );
	return $ocr;
}





sub _get_ocr {
	my ($self,$abs)= @_;
   defined $abs or confess('missing arg');
   $self->{ocr} ||={};
	unless( defined $self->{ocr}->{$abs} ){ 
      # TODO could check that this *IS* one of the files extracted		
      require Image::OCR::Tesseract;      
		my $content = Image::OCR::Tesseract::get_ocr($abs);
		$self->{ocr}->{$abs} = $content;	
	}

	return $self->{ocr}->{$abs};
}




sub get_ocr_arrayref {
	my ($self)= @_;
	
	my $ocr = [];
	for( @{$self->abs_images} ){		
		push @$ocr, $self->get_ocr($_);	
	}

	return $ocr;
}


sub cleanup {
	my $self = shift;

	#unlink $self->abs_tmp;
	for(@{$self->abs_images}){
		unlink $_;		
	}
	return 1;
}

sub DESTROY {
   my $self = shift;
   $self->cleanup;
}


1;


__END__

=pod

=head1 NAME

PDF::OCR - get ocr and images out of a pdf file

=head1 SYNOPSIS

	use PDF::OCR;

	my $p = new PDF::OCR('/path/to/file.pdf');
   
   my $text = $p->get_ocr;


=head2 EXAMPLE 2

	use PDF::OCR;

	my $p = new PDF::OCR('/path/to/file.pdf');
   
	my $images = $p->abs_images; # extract images, get list of paths
	
	for( @{$p->abs_images} ){ # get ocr content for each
	
		my $content = $p->get_ocr($_);
		
		print "image $_ had content: $content\n\n";
	}


	my $ocrs = $p->get_ocr; # get ocr content for all as one scalar with pagebreaks
	
   print "$abs_pdf had [$ocrs]\n";

	# get all content of all images as array ref, each element is one image text content
	my @ocrs = @{ $p->get_ocr_arrayref };

   print "$abs_pdf had [@ocrs]\n";
	
=head1 DESCRIPTION

The whole process does not change your original pdf in any way.

Please note this is only to get text out of images inside the pdf file, it does not check for genuine text inside the file- if any.
For that please see L<PDF::OCR::Thorough>

=head1 METHODS

=head2 new()

Argument is pdf file you want to run ocr on.

	my $o = new PDF::OCR('/path/to/file.pdf');

This will copy the file to a tmp file.

=head2 abs_images()

returns array ref with images extracted from the pdf

=head2 get_ocr()

optional argument is abs path of image extracted from pdf
returns ocr content

if no argument is given, all image ocr contents are concatenated and 
returned as scalar (with pagebreak chars, can be regexed with \f)

=head2 get_ocr_arrayref()

get all ocr images content as array ref

=head2 cleanup()

erase temp file and all image files extracted
called by DESTROY

=head1 BUGS

Please notify the AUTHOR if you find any bugs.

=head1 CAVEATS

This module is for POSIX systems. 
It is not intended to run on other "systems" and no support for such will be added
in the future.

This module is in development, please notify the AUTHOR with any feedback.

=head1 SEE ALSO

L<PDF::GetImages>
L<Image::OCR::Tesseract>
L<PDF::API2>
http://code.google.com/p/tesseract-ocr/

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
