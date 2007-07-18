use Test::Simple 'no_plan';
use lib './lib';
use PDF::OCR;
use strict;
use Cwd;
#use Smart::Comments '###';
my $abs_pdf = cwd().'/t/scan1.pdf';


my $p = new PDF::OCR($abs_pdf);

ok($p,'instanced object');

my $tmp;
ok($tmp = $p->abs_tmp);
### $tmp

my $imgs = $p->abs_images;
ok($imgs,'abs images');

### $imgs


my $ocr = $p->get_ocr;

ok($ocr);

### $ocr;

ok($p->cleanup);


for (@$imgs){
	unlink $_;
}
