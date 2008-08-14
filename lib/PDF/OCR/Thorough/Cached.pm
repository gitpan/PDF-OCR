package PDF::OCR::Thorough::Cached;
use base 'PDF::OCR::Thorough';
use strict;
#use File::Slurp;
use vars qw($ABS_CACHE_DIR $CACHE_BY_SUM);
$ABS_CACHE_DIR = '/tmp/PDF-OCR-Thorough-Cached';
$CACHE_BY_SUM = 0;

sub _slurp {
   my $abs = shift;
   open(FILE,'<', $abs) or die($!);
   local $/;
   my $txt = <FILE>;
   close FILE;
   return $txt;

}

sub _cli_md5sum {
      my $abs = shift;
      my $sum = `md5sum '$abs'`;
      $sum=~s/\s.+$|\s+$//g;
      $sum=~/^\w{32}$/ or die();
      return $sum;
}


sub _sum2file {
   my $sum = shift;
   $sum=~/^(\w{2})/ or die;
   return "$ABS_CACHE_DIR/$1/$sum";
}



# methods ...
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

			open(FILE,">".$self->abs_cached) 
            or die( sprintf "cannot write to %s, $!", $self->abs_cached );
			print FILE $text;
			close FILE;

			$self->{is_cached} = 1;
			$self->{__text} = $text;
		}	
	}		
   
   return $self->{__text};
}


sub _md5sum {
   my $self = shift;
   $self->{md5sum} ||= _cli_md5sum($self->abs_pdf);
   return $self->{md5sum};
}



sub abs_cached {
   my $self = shift;

   my $cached;
   if( $CACHE_BY_SUM ){
      my $sum = $self->_md5sum;
      $cached = _sum2file($sum);
   }
   
   else {
      $cached = $ABS_CACHE_DIR.'/'.$self->abs_pdf.'.txt';
   }


   return $cached;
}

sub _assure_abs_cached_loc {
   my $self = shift;

   my $loc = $self->abs_cached;
   $loc=~s/\/[^\/]+$//;
   -d $loc or File::Path::mkpath($loc) or die("cant make $loc, $!");
   return 1;
}


*set_abs_cache = \&abs_cache;


sub abs_cache {
   my $self = shift;
   carp("abs_cache() is deprecated, use \$".__PACKAGE__."::ABS_CACHE_DIR instead");

   my $abs_cache = shift;

   if (defined $abs_cache){
      $ABS_CACHE_DIR = $abs_cache;
   }

   return $ABS_CACHE_DIR;
}

sub is_cached {
	my $self = shift;
	
	unless( defined $self->{is_cached} ){	
		no warnings;
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
   $PDF::OCR::Thorough::Cached::ABS_CACHE_DIR = '/tmp/cache';
   $PDF::OCR::Thorough::Cached::CACHE_BY_SUM  = 1;

   my $text = $p->get_text;

=head2 $PDF::OCR::Thorough::Cached::ABS_CACHE_DIR

Directory that will be the cache. The directory must exist.
Defaults to '/tmp/PDF-OCR-Thorough-Cached'.

=head2 $PDF::OCR::Thorough::Cached::CACHE_BY_SUM

If you set to true, we set where the files are stored by md5sum.
If the ABS_CACHE_DIR is set to '/tmp/cache' and the md5sum is 209218904fc0d1bfbacdd9d90655f545,
Then the abs_cached() destination would be:
   /tmp/cache/20/209218904fc0d1bfbacdd9d90655f545


=head2 abs_cached() 

Returns abs path to where cached txt of pdf should be.

=head2 is_cached()

Returns boolean.
Does the cached version exist on disk?

=head1 SEE ALSO

L<PDF::OCR>
L<PDF::OCR::Thorough>
tesseract

=head1 AUTHOR

Leo Charre leocharre at cpan dot org
   
