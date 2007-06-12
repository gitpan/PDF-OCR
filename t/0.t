use Test::Simple 'no_plan';
use File::Which 'which';
use lib './lib';
use PDF::GetImages 'pdfimages';
use Image::OCR::Tesseract 'get_ocr';
use Cwd;
use Smart::Comments '###';

### Testing Image OCR Tesseract and PDF GetImages


ok(which('convert'), 'imagemagick convert is installed, and i can find the path to the executable') 
	or die("Is ImageMagick installed properly on this system?");


ok(which('pdfimages'),'pdfimages is installed, and i can find the path to the executable')
	or die("Is xpdf installed properly on this system?");


ok(which('tesseract'),'tesseract is installed, and i can find the path to the executable')
	or die("Is tesseract installed properly on this system?");

	



my $pdf = cwd().'/t/scan1.pdf';

my $images = pdfimages($pdf);

ok(scalar @$images,'pdfimages');


for (@$images){

	my $ocr = get_ocr($_);

	ok($ocr,'tesseract ok');
	### $ocr
	
}
