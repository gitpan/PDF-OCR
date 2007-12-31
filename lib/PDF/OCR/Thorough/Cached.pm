package PDF::OCR::Thorough::Cached;
use base 'PDF::OCR::Thorough';
use strict;
#use File::Slurp;



sub _slurp {
   my $abs = shift;
   open(FILE,'<', $abs) or die($!);
   local $/;
   my $txt = <FILE>;
   close FILE;
   return $txt;

}

sub get_text {
   my $self = shift;

	unless( defined $self->{__text} ){
		if ( $self->is_cached ){
			#my $text = File::Slurp::slurp($self->abs_cached);
         my $text = _slurp($self->abs_cached);
			$self->{__text} = $text;

		}
		else {
			my $text = $self->SUPER::get_text;
			$self->_assure_abs_cached_loc;

			open(FILE,">".$self->abs_cached) or die( sprintf "cannot write to %s, $!", $self->abs_cached );
			print FILE $text;
			close FILE;

			$self->{is_cached} = 1;
			$self->{__text} = $text;
		}	
	}		
   
   return $self->{__text};
}

sub abs_cached {
   my $self = shift;
   my $cached = $self->abs_cache.'/'.$self->abs_pdf.'.txt';
   return $cached;
}

sub _assure_abs_cached_loc {
   my $self = shift;

   my $loc = $self->abs_cached;
   $loc=~s/\/[^\/]+$//;
   -d $loc or File::Path::mkpath($loc) or die("cant make $loc, $!");
   return 1;
}


sub set_abs_cache {
   my ($self, $abs) = @_;
   $self->{abs_cache} = $abs;
   return 1;
}


sub abs_cache {
   my $self = shift;
   unless( $self->{_abs_cache}){
      $self->{abs_cache} ||= '/tmp/PDF-OCR-Thorough-Cached';
      -d $self->{abs_cache} or die("dir $$self{abs_cache} does not exist.");
      $self->{_abs_cache} = $self->{abs_cache};
   }
   return $self->{_abs_cache};   
}

sub is_cached {
	my $self = shift;
	
	unless( defined $self->{is_cached} ){	
		
		$self->{is_cached} =( -f $self->abs_cached ? 1 : 0 );
	}

	return $self->{is_cached};
}



1;

__END__

=pod

=head1 NAME

PDF::OCR::Thorough::Cached - save ocr to text file for easy retrieval

=head1 DESCRIPTION

This is just like PDF::OCR::Thorough, only the text is saved to a text file, so subseuent
retrievals are snap quick.
This inherits all the methods if PDF::OCR::Thorough

=head1 SYNOPSIS

   my $p = new PDF::OCR::Thorough::Cached('/abs/path/file.pdf');
   $p->set_abs_cache('/tmp/cache');

   my $text = $p->get_text;

=head2 set_abs_cache()

argument is a directory that will be the cache, defaults to '/tmp/PDF-OCR-Thorough-Cached'

=head2 abs_cache()

returns directory where we cache

=head2 abs_cached()

returns abs path to where cached txt of pdf should be

=head2 is_cached()

returns boolean 
does the cached version exist on disk?

=head1 SEE ALSO

PDF::OCR

PDF::OCR::Thorough

tesseract

=head1 AUTHOR

Leo Charre leocharre at cpan dot org
   
