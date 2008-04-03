use lib inc; use Devel::AssertOS qw(Unix);

use ExtUtils::MakeMaker;
WriteMakefile(
   NAME              => 'PDF::OCR',
   VERSION_FROM      => 'lib/PDF/OCR.pm', # finds $VERSION
   PREREQ_PM => {
      'Carp'                                             => '1.04',
      'Cwd'                                              => '3.12',
      'Dyer::CLI'                                        => '1.06',
      'File::Copy'                                       => '2.09',
      'File::Find::Rule'                                 => '0.30',
      'File::Path'                                       => '1.08',
      'File::Slurp'                                      => '0',
      'File::Spec'                                       => '3.24',
      'File::Which'                                      => '0.05',
      'Image::OCR::Tesseract'                            => '1.13',
      'PDF::API2'                                        => '2.014',
      'PDF::GetImages'                                   => '1.01',
      'Smart::Comments'                                  => 'v1.0.2',
      'Test::Simple'                                     => '0.7',
   },
   EXE_FILES => [qw(bin/pdf2ocr bin/pdfgetext bin/pdf2ocrturntotext)],
);


