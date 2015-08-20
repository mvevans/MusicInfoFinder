#!/usr/bin/perl -w

use strict;
use warnings;

use MP3::Tag;
use Image::Grab;

use constant APIC => "APIC";
use constant TYPE => "jpg";
use constant HEADER => ( chr(0x0) , "image/" . TYPE , chr(0x3), "Cover Image");
use constant DEBUG => 1;

if (@ARGV < 2) {
    print "Usage: ./$0 image mp3file...\n";
    exit 1;
}

my $imagefile = shift;

my $pic = new Image::Grab;

$pic->url('http://avatars1.githubusercontent.com/u/8057243?v=3&s=460');
$pic->grab;
print "Image Grabbed\n" if DEBUG;
my $imagedata = $pic->image;
undef $pic;

foreach my $mp3file (@ARGV) {
    if ( ! -r $mp3file || ! -w $mp3file ) {
	print "File $mp3file is not rw\n";
	next;
    }

    my $mp3 = MP3::Tag->new($mp3file);
    my @retvla = $mp3->get_tags();

    unless ($mp3) {
	print "Couldn't read MP3 $mp3file: $!\n";
	next;
    }

    my $id3;
    if (exists $mp3->{ID3v2}) {
	print "Using old ID3v2 tag\n" if DEBUG;
	$id3 = $mp3->{ID3v2};
    } else {
	print "Creating new ID3v2 tag\n" if DEBUG;
	$id3 = $mp3->new_tag("ID3v2");
    }

    my $frames = $id3->supported_frames();
    if (!exists $frames->{APIC}) {
	print "Something is wrong, APIC is not a supported frame!\n";
	exit 2;
    }

    my $frameids = $id3->get_frame_ids();
    if (exists $$frameids{APIC}) {
	print "Replacing existing APIC entry\n" if DEBUG;
	$id3->change_frame(APIC, HEADER, $imagedata);
    } else {
	print "Creating new APIC entry\n" if DEBUG;
	$id3->add_frame(APIC,HEADER, $imagedata);
    }

    $id3->write_tag();
    $mp3->close();
    print "Successfully added Image to $mp3file\n";
    
}