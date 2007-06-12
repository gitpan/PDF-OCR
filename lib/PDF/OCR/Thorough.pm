package PDF::OCR::Thorough;
use strict;
use warnings;
use Carp;
use Cwd;
use File::Copy;
use File::Which 'which';
use File::Path;
use PDF::API2;
use PDF::GetImages;
use Image::OCR::Tesseract;

$PDF::OCR::Thorough::DEBUG = 0;
sub DEBUG : lvalue {$PDF::OCR::Thorough::DEBUG}

=pod

=head1 NAME

PDF::OCR::Thorough - extract text fom pdf document resorting to ocr as needed

=head1 SYNOPSIS

	use PDF::OCR::Thorough;

	my $abs_pdf = '/home/myself/file.pdf';

	my $p = new PDF::OCR::Thorough($abs_pdf);

	my $text = $p->get_text;

=head1 DESCRIPTION

unlike PDF::OCR which assumes each page in the pdf document is a page scan- This script is more thorough.

1) the original.pdf is copied to tmp.pdf
2) tmp.pdf is split into page1.pdf page2.pdf etc..
3) for each pageX.pdf, first we try reading with pdftotext, if the result is too small we try to read with Image::OCR::Tesseract
4) the output of each is merged with newpage chars 

The output to STDOUT is all the text of all pages, but it is separated with newpage characters. These can be matched with a regex \f

Please note the PDF::API2 is used to check that the pdf data is valid.

This is part of the PDF::OCR Package.

=head1 METHODS

=cut

sub new {
	my($class, $arg) = @_;
	$arg or croak("missing argument to constructor");	
	my $self = {};

	$self->{abs_pdf} = Cwd::abs_path($arg) or croak("[$arg] not resolving with Cwd::abs_path()");
	bless $self, $class;
	
	$self->pdf_data_ok or warn("the file ".$self->abs_pdf." does not check ok with PDF::API2") and return;
	
	return $self;
}

=head2 new()

argument is the abs path to the pdf you want to read text from.

	my $p = new PDF::OCR::Thorough('/home/myself/myfile.pdf');

If the file is not there or the pdf data is corrupt, warns and returns undef.

=cut

sub pdf_data_ok {
	my $self = shift;
	unless( defined $self->{pdf_data_ok}) {
		my $result = eval { PDF::API2->open($self->abs_pdf) };
		$result ||=0;		
		$self->{pdf_data_ok} = $result;
	}
	return $self->{pdf_data_ok};
}

=head2 pdf_data_ok()

takes no argument, checks if the pdf is ok, of PDF::API2 can open it
This is called by constructor.

=cut

sub abs_tmp_pdf {
	my $self = shift;
	unless( $self->{abs_tmp_pdf} ){
		$self->{abs_tmp_pdf} = $self->abs_tmp.'/'.$self->filename;
		File::Copy::cp($self->abs_pdf, $self->abs_tmp_pdf);	 # muahahaha
		print STDERR $self->abs_pdf .' copied to '.$self->abs_tmp_pdf."\n" if DEBUG;
	}
	return $self->{abs_tmp_pdf};
}

=head2 abs_tmp_pdf()

returns abs path to where the temp copy of the pdf is

=cut

sub filename {
	my $self = shift;
	my $filename = $self->abs_pdf;
	$filename=~s/^.+\/+//;
	return $filename;	
}

=head2 filename()

returns filename of the original pdf provided as argument to constructor

=cut

sub pages {
	my $self = shift;

	my $count = scalar @{$self->abs_pages};
	$count ||= 0;
	return $count;	
}

=head2 pages()

returns number of page files extracted

=cut

sub abs_tmp {
	my $self = shift;
	unless( $self->{abs_tmp} ){
		$self->{abs_tmp} = '/tmp/'.$self->_tmpid;
		mkdir $self->{abs_tmp};
		print STDERR "abs tmp created: ".$self->{abs_tmp}."\n" if DEBUG;
	}
	return $self->{abs_tmp};
}

=head2 abs_tmp()

returns abs path to the temp dir created
this is where the copy of your file resides, together with any images extracted, and page files extracted.

=cut

sub abs_pdf {
	my $self = shift;	
	unless($self->{checked}){
		-f $self->{abs_pdf} or croak("is not file: $$self{abs_pdf}");
		$self->{checked}=1;		
	}
	return $self->{abs_pdf};
}

=head2 abs_pdf()

abs path to your original pdf provided as argument to constructor

=cut

sub _tmpid {
	my $self = shift;
	$self->{tmpid} ||= time.int(rand(20000));
	return $self->{tmpid};
}


sub _abs_images {
	my($self,$abs_pdf) =@_; $abs_pdf or croak('missing abs pdf argument to _abs_images');	

	print STDERR "_abs_images [$abs_pdf]\n" if DEBUG;
	$self->{abs_images} ||={};

	unless( defined $self->{abs_images}->{$abs_pdf} ){
		
		my $images = PDF::GetImages::pdfimages($abs_pdf); 
		$images ||=[];		
		$self->{abs_images}->{$abs_pdf} = $images;	
		
		#if (DEBUG){
		#	print STDERR "got images out of $abs_pdf:\n";
		#	map { print STDERR " $_\n" } @{$images};
		#}		
	}

	return $self->{abs_images}->{$abs_pdf};
}

sub abs_images {
	my($self,$abs_page) = @_;
	
	unless(defined $abs_page){
		my @imgs;
		for(@{$self->abs_pages}){
			push @imgs, @{$self->_abs_images($_)};
		}	
		return \@imgs;
	}

	return $self->_abs_images($abs_page);	
}

=head2 abs_images()

optional argument is abs path to a page file ( see abs_pages() ).
if no argument provided, returns abs path to all images extracted from all pages.

=cut

sub _pdftotext {
	my $self = shift;
	$self->{pdftotextbin} ||= which('pdftotext') or die("missing pdftotext?");
	return $self->{pdftotextbin};
}

sub _get_page_text {
	my ($self,$abs_page) =@_;

	$self->{pagetext} ||= {};
	
	unless ( defined $self->{pagetext}->{$abs_page} ){
		print STDERR "_get_page_text for [$abs_page]\n" if DEBUG;
	
		my $text = '';

		#first try pdftotext
		my @command = ($self->_pdftotext,'-q',$abs_page);
		system(@command); # dont try ==0, it's fruked up
		my $out = $abs_page; $out=~s/\.pdf/.txt/;

		if( -f $out	){
			$text = File::Slurp::slurp($out);
			print STDERR "text from pdftotext [$text]\n\n" if DEBUG;
		}
	
		if (length($text) <6 ){
			print STDERR "pdftotext string is too small\n" if DEBUG;	
		}

		if( length($text) <6 or $self->force_ocr){
			print STDERR "extracting images for ocr\n" if DEBUG;

			my $imgstext;

			for( @{$self->abs_images($abs_page)}){
				$imgstext.= $self->get_ocr($_);
				print STDERR "got ocr for $_\n" if DEBUG;
			}	
		
			$text.=$imgstext;
		}
	
		unless( length($text) > 5 ){
			print STDERR "Content is negligible\n" if DEBUG;
		}

		$self->{pagetext}->{$abs_page} = $text;	
	}

	return $self->{pagetext}->{$abs_page};
}

sub get_page_text {
	my ($self,$abs_page) = @_;	

	if ($abs_page =~/^\d+$/){
		
		my $abs = @{$self->abs_pages}[($abs_page+1)];
		defined $abs or warn("Page [$abs_page] does not exist?") and return;

		print STDERR " getting page $abs_page\n" if DEBUG;
		$abs_page = $abs;
	}

	my $text = $self->_get_page_text($abs_page);
	return $text;
}

=head2 get_page_text()

argument is page number or abs path to page file (there is no page 0)
returns text inside
See also get_text()

=cut

sub get_ocr {
	my($self,$abs_image) = @_;
	$self->{imgocr} ||={};
	unless( defined $self->{imgocr}->{$abs_image} ){
		my $imgtext = Image::OCR::Tesseract::get_ocr($abs_image);			
		$imgtext ||='';
		$self->{imgocr}->{$abs_image} =$imgtext;		
	}
	return $self->{imgocr}->{$abs_image};	
}

=head2 get_ocr()

argument is abs path to image file
returns ocr text
this is also cached in object

=cut

sub force_ocr {
	my $self = shift;
	my $val = shift;
	if (defined $val){
		$self->{force_ocr} = $val;
	}
	$self->{force_ocr} ||= 0;
	return $self->{force_ocr};
}

=head2 force_ocr()

argument is boolean 1/0
force extracting images and running ocr even if pdftotext finds content
returns value

You would want to set this to 1 if you expect your iamge to contain both text and large images
perhaps with text also, and you want both extracted.

=cut

sub _pdftk {
	my $self = shift;
	$self->{pdftkbin} ||= which('pdftk') or die("pdftk not installed?");
	return $self->{pdftkbin};
}

sub abs_pages {
	my $self = shift;
	unless( defined $self->{abs_pages} ){
	
		my ($abs_tmp, $tmpid, $abs_tmp_pdf,$abs_pdf)=($self->abs_tmp, $self->_tmpid, $self->abs_tmp_pdf, $self->abs_pdf);		

		my $abs_outputname = $abs_tmp.'/'.$tmpid.'_page_%04d.pdf';
		print STDERR " abs outputname format : $abs_outputname\n" if DEBUG;
		

		my @args = ($self->_pdftk, $abs_tmp_pdf,'burst','output',$abs_outputname );
		system(@args) == 0 
			or die("system @args - $?");			

		print STDERR " pdftkburst ok for $abs_tmp_pdf\n" if DEBUG;

		opendir(DIR, $abs_tmp);
		my @abs_pages = map { $_=~s/^/$abs_tmp\//; $_ } sort grep { /$tmpid\_page_\d+\.pdf/  } readdir DIR;
		closedir DIR;

		scalar @abs_pages or die("no pages in $abs_pdf"); # or just warn() ?

		if (DEBUG){
			print STDERR "pagefiles:\n";
			map { print STDERR " $_\n" } @abs_pages;
		}

		$self->{abs_pages} = \@abs_pages;
	}

	return $self->{abs_pages};
}

=head2 abs_pages()

returns abs paths to burst pdf pages

=cut


sub get_text {
	my ($self )= shift;

	unless( defined $self->{text}){
		my $text='';
		for(@{$self->abs_pages}){
			$text.= $self->get_page_text($_);	
		}
		$self->{text} = $text;
	}
	
	return $self->{text};
}

=head2 get_text()

returns all text in all pages, separated by \f newpage chars.
See also get_page_text()

=cut


sub cleanup {
	my $self= shift;
	File::Path::rmtree($self->abs_tmp);
	return 1;
}

=head2 cleanup()

removes all temp content
pretty rough, uses File::Path::rmtree()
returns true.

=head1 CAVEATS

Will not work with a corrupted pdf file.
But it does test for that, so if it doesn't work, you know if it's because the PDF doc is messed up according to PDF::API2.

=head1 SEE ALSO

L<PDF::OCR>
L<PDF::API2>

=head1 REQUIREMENTS

File::Copy, PDF::API2, PDF::GetImages, Image::OCR::Tesseract, File::Which

=head1 NON PERL REQUIREMENTS

tesseract
pdftk
xpdf pdftotext

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

1;







