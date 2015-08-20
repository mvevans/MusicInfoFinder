use strict;
use warnings;
use Carp::Always;
require MP3::Tag;
use File::Find::Rule;
use File::Basename;
use JSON::Parse 'parse_json';
use Switch;
require LWP::UserAgent;
use String::Util qw(trim);
MP3::Tag->config(write_v24 => 1);

my $dir = 'H:\Users\Copper_top\Music\musica';
my @foundFiles = File::Find::Rule->file()->name( '*.mp3' )->in( $dir );

my $resultLimit = 5;

my $urlPrefix = 'http://itunes.apple.com/search?term=';
my $urlSearch = '';
my $urlSuffix = '&media=music&limit='.$resultLimit;

my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
$ua->timeout(10);
$ua->env_proxy;

open(LOG, "> log.csv");
foreach my $file (@foundFiles){

	my $titleTag = "";
	my $albumTag = "";
	my $artistTag = "";
	
	my $mp3 = MP3::Tag->new($file);
	$mp3->get_tags();
	
	if (exists $mp3->{ID3v2})
	{
	
		# get a list of frames as a hash reference
		my $frames = $mp3->{ID3v2}->get_frame_ids();
		next if (exists $$frames{APIC} && exists $$frames{TALB});
		# process each tag
		foreach my $frame (keys %$frames) 
		{
			if($frame =~ m/(TIT2|TALB|TPE1)/){#only gets certain frames
				# get a key-value pair of content-description
				my ($value, $desc) = $mp3->{ID3v2}->get_frame($frame);
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
					$value =~ s/.*(?:www\.|http|\.com|\.net).*//ig;#get websites out
					switch ($frame){
						case "TIT2"	{$titleTag = $value;}
						case "TALB"	{$albumTag = $value;}
						case "TPE1"	{$artistTag = $value;}
					}
				}
			}
		}
	}
	my($fName, $fDir, $fSuffix) = fileparse($file);
	$fName =~ s/\.\w{3}$//;
	print "$fName: $titleTag By $artistTag on $albumTag \n";
	
	#easier way to do this is to use regex but I'm lazy 
	#TODO: needs a way to pull out a dash
	$urlSearch=join('+',split(/\s+/,$fName));
	
	unless($artistTag eq ""){
		$urlSearch .= '+'.join('+',split(/\s+/,$artistTag));
	}
	
	print "search string: '$urlSearch'\n";
	
	my $webResults = $ua->get($urlPrefix.$urlSearch.$urlSuffix);
	my $webResultsJSON = trim($webResults->content);
	
	#print $webResultsJSON."\n";
	
	my $parsedResults = parse_json ($webResultsJSON);
	#print ref $parsedResults, "\n";
	my %parsedResults = %{ $parsedResults };
	my $resultCount = $parsedResults{'resultCount'};
	if ($resultCount == 0){
		print LOG "$fName,$urlSearch\n";
		print "\n------ No Results Found ------\n\n";
		next;
	}
	my @results = @{ $parsedResults{'results'} };#array of results
	foreach my $result (@results){
		print ref $result."\n\n";
		my %result = %{ $result };
		foreach my $key (keys %result) {
			print "\t $key : $result{$key}\n";
			#title,artist,alb artist,alb,year,length,art,genre
		}
		print "***\n";
	}
	#foreach my $key (keys %hash) { ... }
	
	print "\n------------\n\n";
}
close(LOG);
close(LOG);