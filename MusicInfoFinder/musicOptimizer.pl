
use strict;
use warnings;
use Carp::Always;
use MP3::Tag;
use File::Find::Rule;
use File::Basename;
use Switch;
MP3::Tag->config(write_v24 => 1);

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


open(LOG, "> log.txt");
foreach my $file (@foundFiles){
	
	my $titleTag = "";
	my $albumTag = "";
	my $genreTag = "";
	my $artistTag = "";
	my $albumArtistTag = "";
	my $yearTag = "";
	my $trackTag = "";
	
	my $mp3 = MP3::Tag->new($file);
	$mp3->get_tags();

	# if ID3v2 tags exists
	if (exists $mp3->{ID3v2})
	{
		#print "***$file***\n";
		#print LOG "***$file***\n";
		# get a list of frames as a hash reference
		my $frames = $mp3->{ID3v2}->get_frame_ids();

		# iterate over the hash
		# process each frame
		foreach my $frame (keys %$frames) 
		{
			if($frame =~ m/(TIT2|TALB|TYER|TCON|TPE1|TPE2|TRCK)/){#only gets certain frames
				# get a key-value pair of content-description
				my ($value, $desc) = $mp3->{ID3v2}->get_frame($frame);
				#print "$frame $desc: ";
				#print LOG "$frame $desc: ";
				# sometimes the value is itself a hash reference containing more values
				# deal with that here
				if (ref $value)
				{
					while (my ($k, $v) = each (%$value))
					{
						#print "\n     - $k: $v";
						#print LOG "\n     - $k: $v";
					}
					#print "\n";
					#print LOG "\n";
				}
				else
				{
					#print "$value\n";
					$value =~ s/.*(?:www\.|http|\.com|\.net).*//ig;#get websites out
					switch ($frame){
						case "TIT2"	{$titleTag = $value;}
						case "TALB"	{$albumTag = $value;}
						case "TYER"	{$yearTag = $value;}
						case "TCON"	{$genreTag = $value;}
						case "TPE1"	{$artistTag = $value;}
						case "TPE2"	{$albumArtistTag = $value;}
						case "TRCK"	{($trackTag) = $value =~ m/^(\d*)/;}
					}
					#print LOG "$value\n";
				}
			}
		}
	#print "\n";
	#print LOG "\n";
	}

	# clean up
	
	
	my($fName, $fDir, $fSuffix) = fileparse($file);
	#print $fDir."\n";
	#print LOG "$fName,$titleTag,$artistTag,$trackTag\n";
	my($nName,$nTitleTag,$nArtistTag) = renamefile($fName,$titleTag,$artistTag,$trackTag);
	if(($nTitleTag ne $titleTag) || ($artistTag ne $nArtistTag)){
		if (defined($nTitleTag) && $nTitleTag ne ""){
			unless(defined($titleTag)){
				$mp3->{ID3v2}->add_frame("TIT2",$nTitleTag);
			}else{
				$mp3->{ID3v2}->change_frame("TIT2",$nTitleTag);
			}
		}
		if (defined($nArtistTag) && $nArtistTag ne ""){
			unless(defined($artistTag)){
				$mp3->{ID3v2}->add_frame("TPE1",$nArtistTag);
			}else{
				$mp3->{ID3v2}->change_frame("TPE1",$nArtistTag);
			}
		}
		my $id3v2 = $mp3->{ID3v2};
		$id3v2->write_tag();
	}
	$mp3->close();
	rename "$fDir$fName", "$fDir$nName" or print "couldn't rename";
	
}
close LOG;


sub renamefile{
	my ($name,$title,$artist,$track) = @_;
	my $n1 = $name;
	#print $name."\n";
	my ($ex) = $name =~ m/(\.\w{3})$/;
	$name =~ s/\.\w{3}$//;
	foreach my $strin (@strings){#removes junk out of file name
		$name =~ s/\Q$strin\E//i;
		$title =~ s/\Q$strin\E//i;
	}
	
	$name =~ s/_/ /ig;#underscores to space
	$name =~ s/\[/\(/ig;#brack -> paren
	$name =~ s/\]/\)/ig;#brack -> paren
	$name =~ s/\(\s*\)//ig;#gets rid of empty paren from deleted junk
	$name =~ s/^\s*//i;#gets rid of space at beginning
	$name =~ s/\s*$//i;#gets rid of space at end
	$name =~ s/\s+/ /ig;#adjust all spaces
	$name =~ s/\s*\(?feat\./ (feat\./ig;
	$name =~ s/\s*\b?(\(?)[^\w](?:ft|featuring|feat)\.?\s*/ \(feat. /ig;#standardizes featuring
	$name =~ s/\Q&amp;\E/&/ig;#fix ampersands
	$name =~ s/\s+w$//i;#grab any straggling w's from w/...
	$name =~ s/\-+$//;#random dashes at end
	
	unless ($track eq ""){
		$name =~ s/^0?\Q$track\E\.?\s*\-?\s*//i;#removes track number from front of file name
	}
	
	unless($title eq ""){
		$title =~ s/_/ /ig;#underscores to space
		$title =~ s/\[/\(/ig;#brack -> paren
		$title =~ s/\]/\)/ig;#brack -> paren
		$title =~ s/\(\s*\)//ig;#gets rid of empty paren from deleted junk
		$title =~ s/^\s*//i;#gets rid of space at beginning
		$title =~ s/\s*$//i;#gets rid of space at end
		$title =~ s/\s+/ /ig;#adjust all spaces
		$title =~ s/\b?(\(?)[^\w](?:ft|featuring|feat)\.?\s*/ \(feat. /ig;#standardizes featuring
		$title =~ s/\Q&amp;\E/&/ig;#fix ampersands
		$title =~ s/\s+w$//i;#grab any straggling w's from w/...
		$title =~ s/\s*\-+$//;#random dashes at end
	}

	if(($title ne "" || $artist ne "") && $name =~ /\-/){
		my $name1 = $name;
		my @parens = $name1 =~ m/(\(.*?(?:feat|mix|version|original|studio|rmx|extended|remastered).*?\))/ig;
		$name1 =~ s/(\(.*?(?:feat|mix|version|original|studio|rmx|extended|remastered).*?\))//ig;
		my $append = join(" ",@parens);
		unless($append =~ /^\s*$/){
			print LOG "will append \'$append\'; name:'$name' name1:'$name1'\n";
		}
		my @artistTitle;
		@artistTitle = split(/\s*\-\s*/,$name1);
		if ($#artistTitle == 1){#there's only one dash
			unless($title eq ""){
				if($artistTitle[1] =~ m/\Q$title\E/i || $title =~ m/\Q$artistTitle[1]\E/i){
					unless($artist eq ""){
						if($artistTitle[0] =~ m/\Q$artist\E/i || $artist =~ m/\Q$artistTitle[0]\E/i){
							print LOG $name."\t".$artistTitle[1]." is the title and ".$artistTitle[0]." is the artist\n\n";
							$name = $artistTitle[1].$append;
						}
					}else{
						print LOG $name."\t".$artistTitle[1]." is the title and ".$artistTitle[0]." is the artist\n\n";#change artist
						$artist = $artistTitle[0];
						$name = $artistTitle[1].$append;
					}
				}elsif($artistTitle[0] =~ m/\Q$title\E/i || $title =~ m/\Q$artistTitle[0]\E/i){
					if($artist ne ""){
						if($artistTitle[1] =~ m/\Q$artist\E/i || $artist =~ m/\Q$artistTitle[1]\E/i){
							print LOG $name."\t".$artistTitle[0]." is the title and ".$artistTitle[1]." is the artist\n\n";
							$name = $artistTitle[0].$append;
						}
					}else{
						print LOG $name."\t".$artistTitle[0]." is the title and ".$artistTitle[1]." is the artist\n\n";#change artist
						$name = $artistTitle[0].$append;
						$artist = $artistTitle[1];
						
					}
				}
			}else{
				if($artistTitle[0] =~ m/\Q$artist\E/i || $artist =~ m/\Q$artistTitle[0]\E/i){
					print LOG $name."\t".$artistTitle[1]." is the title and ".$artistTitle[0]." is the artist\n\n";
					$name = $artistTitle[1].$append;
					$title = $artistTitle[1].$append;
				}elsif($artistTitle[1] =~ m/\Q$artist\E/i || $artist =~ m/\Q$artistTitle[1]\E/i){
					print LOG $name."\t".$artistTitle[0]." is the title and ".$artistTitle[1]." is the artist\n\n";
					$name = $artistTitle[0].$append;
					$title = $artistTitle[0].$append;
				}
			}	
			#place check for no match at all
		}
	}
	
	if($title eq "" && $artist ne "" && $name !~ /\-/){
		$title = $name;
	}
		
	
	
	$name .= $ex;
	print $name."\n";
	#unless($n1 eq $name){print $n1." -> ".$name."\n";};
	return ($name,$title,$artist);
}
# and output them all
#print join("\n",@foundFiles), "\n";