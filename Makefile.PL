use ExtUtils::MakeMaker;
WriteMakefile(
NAME              => 'PDF::OCR',
VERSION_FROM      => 'lib/PDF/OCR.pm', # finds $VERSION
PREREQ_PM         => {
   'PDF::GetImages'        => '1.01',
   'Image::OCR::Tesseract' => '1.03',
   'File::Copy' => 0,
   'Smart::Comments' => 0,
   'File::Path' => 0,					 
   'File::Which' => 0,
   'Carp' => 0,
   'Image::Magick' => 6,		
   'PDF::API2'=> 0,
   'LEOCHARRE::CLI' => '1.12',
   },
   EXE_FILES => [qw(bin/pdf2ocr bin/pdfgetext bin/pdf2ocrturntotext)],
);
