use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'PDF::OCR',
    VERSION_FROM      => 'lib/PDF/OCR.pm', # finds $VERSION
    PREREQ_PM         => {
					 'File::Copy' => 0,
                #'File::Slurp' => 0,
					 'Smart::Comments' => 0,
					 'File::Path' => 0,					 
					 'File::Which' => 0,
					 'Carp' => 0,
		          'Image::Magick' => 0,		
					 'PDF::API2'=> 0,
					 'File::Which' => 0,
					 'LEOCHARRE::CLI' => 0,
					 },
    EXE_FILES               => [qw(bin/pdf2ocr bin/ocr bin/pdfgetext bin/pdf2ocrturntotext)],
);
