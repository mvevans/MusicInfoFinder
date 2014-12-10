
use strict;
use warnings;

use MP3::Tag;
use File::Find::Rule;
use File::Basename;

my $dir = 'H:\Users\Copper_top\Music\musica';
my @foundFiles;

open(STR, "< strings.txt");
my @strings = <STR>;
close STR;
for (my $y = 0; $y <= $#strings; $y++){
	chomp($strings[$y]);
}


#file collection
#find( sub { push @foundFiles, $File::Find::name if /\.mp3$/ }, $dir );
@foundFiles = File::Find::Rule->file()->name( '*.mp3' )->in( $dir );



foreach my $file (@foundFiles){

	my($fName, $fDir, $fSuffix) = fileparse($file);
	#print $fDir."\n";
	my $nName = renamefile($fName);
	rename "$fDir$fName", "$fDir$nName" or print "couldn't rename";

}

sub renamefile{
	my ($name) = @_;
	my $n1 = $name;
	#print $name."\n";
	my ($ex) = $name =~ m/(\.\w{3})$/;
	$name =~ s/\.\w{3}$//;
	foreach my $strin (@strings){
		$name =~ s/\Q$strin\E//i;
	}
	
	$name =~ s/\[\s*\]//ig;
	$name =~ s/\(\s*\)//ig;
	$name =~ s/^\s*//i;
	$name =~ s/\s*$//i;
	$name =~ s/\s+/ /ig;
	$name =~ s/(?:ft|featuring|feat)\.?\s*/feat. /ig;
	$name =~ s/\Q&amp;\E/&/ig;
	
	$name .= $ex;
	#print $name."\n";
	unless($n1 eq $name){print $n1." -> ".$name."\n";};
	return $name;
}
print join("\n",@strings), "\n";
# and output them all
#print join("\n",@foundFiles), "\n";