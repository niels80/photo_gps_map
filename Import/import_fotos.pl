
# Photo Import V0.1
# Niels Ehlers

use strict;
use DBI;
use Config::Simple;
use Digest::SHA;
use Image::ExifTool qw(:Public);
use File::Find::Rule;
use File::Copy qw(copy);
use File::Basename;
use Data::Dumper;
use DateTime;
use utf8;

my $cfg = new Config::Simple( $ARGV[0] )
  or die 'Usage: perl import_fotos.pl config_file';

my $DBGLEVEL = $cfg->param("GENERAL.DEBUGLEVEL");
my $TIMEZONE = $cfg->param("GENERAL.TIMEZONE");

# Connect to Database
my $dsn = 
    "DBI:MariaDB:database="
  . $cfg->param('DATABASE.DB_DATABASE')
  . ";host="
  . $cfg->param('DATABASE.DB_HOSTNAME');

my $dbh = DBI->connect(
    $dsn,
    $cfg->param('DATABASE.DB_USER'),
    $cfg->param('DATABASE.DB_PASSWORD')
);

# Init Exif-Tool
my $exifTool = new Image::ExifTool;
$exifTool->Options( DateFormat  => "%s" );
$exifTool->Options( CoordFormat => q{%.8f} );

# Find files
my @basedirs = $cfg->param('IMAGES.IMPORT_FOLDERS');
my @uc       = $cfg->param('IMAGES.FILE_TYPES');
my @lc       = $cfg->param('IMAGES.FILE_TYPES');
$_ = lc for @lc;
$_ = uc for @uc;

my $rule = File::Find::Rule->new();
$rule->file();
$rule->name( @lc, @uc );
my @files = $rule->in(@basedirs);
@files = sort @files;

# Iterate over files
foreach my $file (@files) {

	# Init variables
	my $tsCreate 	= -1;
	my $idAccuracy 	= -1; # Trust level of Date
	my $ts 			= time();
	
    # Get File Name Info
    my @fileinfo = fileparse($file);
    my $filebase = "";
    my $filedir  = $fileinfo[1];
    my $filename = $fileinfo[0];
    foreach my $basedir (@basedirs) {
        if ( $DBGLEVEL > 2 ) { print "Checking Basedir $basedir\n" }
        if ( $filedir =~ /$basedir/ ) {
            $filebase = $basedir;
            $filedir =~ s/$basedir//g;
        }
    }
	
	
	if ( $DBGLEVEL > 0 ) { print "Importing $file ...\n" }
    if ( $DBGLEVEL > 2 ) { print " - BASE:  $filebase \n" }
    if ( $DBGLEVEL > 2 ) { print " - DIR:   $filedir \n" }
    if ( $DBGLEVEL > 2 ) { print " - NAME:  $filename \n" }
	
	
    # Extract date from Folder name
	my ( $yyyy, $mm ) = $filedir =~ /(\d{4})_(\d{2}).+/;
	my ($dd) = $filedir =~ /\d{4}_\d{2}_(\d{2}).+/;
	if ( !defined $dd ) { $dd = 1; }

	if ( defined $yyyy ) {
		my $dt = DateTime->new(
			year      => $yyyy,
			month     => $mm,
			day       => $dd,
			hour      => 0,
			minute    => 0,
			second    => 0,
			time_zone => $TIMEZONE,
		);
		$tsCreate = $dt->epoch();
		$idAccuracy = 4;
		if ( $DBGLEVEL > 1 ) {
			print " - Found time from folder name: ". &get_time_formatted($tsCreate) . " \n";
		}
		
	}
	
	my $gps_lon = "NULL";
    my $gps_lat = "NULL";
    my $gps_alt = "NULL";
	
	# Read Folder Config file if exists
    my $file_local_conf = $filebase . $filedir . "gallery.cfg";
    if ( -e $file_local_conf ) {
        if ( $DBGLEVEL > 2 ) { print " - Found local config file \n" }
        my $cfg2 = new Config::Simple($file_local_conf);
        if ( defined $cfg2->param('NOIMPORT') ) {
            if ( $DBGLEVEL > 2 ) {
                print " - File is in a private folder and shall not be imported (local config). Skipping!";
            }
            next;
        }
        if ( defined $cfg2->param('GPS_LAT') ) {
            if ( $DBGLEVEL > 1 ) { print " - Found default GPS coordinates" }
            $gps_lat = $cfg2->param('GPS_LAT');
        }
        if ( defined $cfg2->param('GPS_LON') ) {
            $gps_lat = $cfg2->param('GPS_LON');
        }
        if ( defined $cfg2->param('GPS_ALT') ) {
            $gps_lat = $cfg2->param('GPS_ALT');
        }
		if ( defined $cfg2->param('DATE') ) {
			my ( $yyyy, $mm ) = $filedir =~ /(\d{4})-(\d{2}).+/;
			my ($dd) = $filedir =~ /\d{4}-\d{2}-(\d{2}).+/;
			if ( !defined $dd ) { $dd = 1; }

			if ( defined $yyyy ) {
				my $dt = DateTime->new(
					year      => $yyyy,
					month     => $mm,
					day       => $dd,
					hour      => 0,
					minute    => 0,
					second    => 0,
					time_zone => $TIMEZONE,
				);
				$tsCreate = $dt->epoch();
				$idAccuracy = 3;
			}
		}
    }

    # Calculate SHA256 Checksum
    my $sha_state = Digest::SHA->new(256);
    $sha_state->addfile( $file, 'p' )
      ; # Important: p = Portable mode to have same line endings in Windows and Unix
    my $sha256 = $sha_state->hexdigest();

    # EXIF Import
    my $success = $exifTool->ExtractInfo($file);
    my $exif    = $exifTool->GetInfo(
        'ImageWidth',   'ImageHeight', 'Orientation',      'GPSLatitude',
        'GPSLongitude', 'GPSAltitude', 'DateTimeOriginal', 'GPSDateTime'
    );

    # EXIF Orientation
    my $id_orientation  = 0;
    my $rotate          = 0;
    my $flip_horizontal = 0;
    my $flip_vertical   = 0;

    my $sql =
      "SELECT * FROM orientation WHERE NAME = '" . $exif->{'Orientation'} . "'";
    my $sth = $dbh->prepare($sql)
      or die 'SQL prepare statement failed: ' . $dbh->errstr();
    $sth->execute() or die 'SQL execution failed: ' . $dbh->errstr();
    if ( $sth->rows() < 1 ) {
       if ( $DBGLEVEL > 2 ) { print " - ORIENTATION: Unknown \n"};
    }
    else {
        if ( $DBGLEVEL > 2 ) {print " - ORIENTATION: " . $exif->{'Orientation'} . "\n"};
        my $ref = $sth->fetchrow_hashref();
        $id_orientation  = $ref->{'ID_ORIENTATION'};
        $rotate          = $ref->{'ROTATION'};
        $flip_horizontal = $ref->{'FLIP_HORIZONTAL'};
        $flip_vertical   = $ref->{'FLIP_VERTICAL'};
    }

    # EXIF GPS
    if ( defined $exif->{'GPSLatitude'} ) {
        $gps_lat = $exif->{'GPSLatitude'};
        $gps_lat =~ s/ //g;
        if ( $gps_lat =~ /N/ ) {
            $gps_lat =~ s/N//g;
        }
        else {
            $gps_lat =~ s/S//g;
            $gps_lat *= -1;
        }
	}
	if ( defined $exif->{'GPSLongitude'} ) {
        $gps_lon = $exif->{'GPSLongitude'};
        $gps_lon =~ s/ //g;
        if ( $gps_lon =~ /E/ ) {
            $gps_lon =~ s/E//g;
        }
        else {
            $gps_lon =~ s/W//g;
            $gps_lon *= -1;
        }
	}
	if ( defined $exif->{'GPSAltitude (1)'} ) {
        $gps_alt = $exif->{'GPSAltitude (1)'};
        $gps_alt =~ s/ //g;
        $gps_alt =~ s/m//g;
    }
	if ( $DBGLEVEL > 1 && defined($exif->{'GPSLongitude'})) {
            print " - Found GPS coordinates: $gps_lat / $gps_lon / $gps_alt \n";
    }
	#die Dumper($exifTool->ImageInfo($file));
	
    # EXIF Image Size
    my $imgWidth  = $exif->{'ImageWidth'};
    my $imgHeigth = $exif->{'ImageHeight'};

    # EXIF Image Time
    if ( defined $exif->{'GPSDateTime'} ) {
        $tsCreate = $exif->{'GPSDateTime'};
		$idAccuracy = 1; 
        if ( $DBGLEVEL > 1 ) {
            print " - Found GPS Time: ". &get_time_formatted($tsCreate) . " \n";
        }
    }
    elsif ( defined $exif->{'DateTimeOriginal'} ) {
        $tsCreate = $exif->{'DateTimeOriginal'};
		$idAccuracy = 2;
        if ( $DBGLEVEL > 1 ) {
            print " - Found Original Time: " . &get_time_formatted($tsCreate) . " \n";
        }
    } elsif (defined $exif->{'FileModifyDate'} ) {
	   my $ts0 = $exif->{'FileModifyDate'};
	   if ($ts0 < $tsCreate + 32 * 24 * 60 * 60) {
			$tsCreate = $ts0;
			$idAccuracy = 5;
	   }
	}
		
	$sql =   "INSERT INTO fotos(GPS_LAT,GPS_LON,GPS_ALT,TS_CREATE,ID_TIME_ACCURACY,WIDTH,HEIGHT,ID_ORIENTATION,FILE_BASE,FILE_DIR,FILE_NAME,TS_IMPORT,SHA256) VALUES \n";
	$sql .=  "(".$gps_lat.",".$gps_lon.",".$gps_alt.",".$tsCreate.",".$idAccuracy.",".$imgWidth.",".$imgHeigth.",".$id_orientation.",'".$filebase."','".$filedir."','".$filename."',".$ts.",'".$sha256."') \n"; 
	$sql .=  "ON DUPLICATE KEY UPDATE \n";
	$sql .=  " GPS_LAT = ".$gps_lat.", \n";
	$sql .=  " GPS_LON = ".$gps_lon.", \n";
	$sql .=  " GPS_ALT = ".$gps_alt.", \n";
	$sql .=  " TS_CREATE = ".$tsCreate.", \n";
	$sql .=  " ID_TIME_ACCURACY = ".$idAccuracy."\n";
	$sth = $dbh->prepare($sql) or die Dumper($exif)."\n\nSQL prepare statement failed: " . $dbh->errstr(). " SQL: \n\n----------------------\n".$sql."\n----------------------\n";
    $sth->execute() or die Dumper($exif)."\n\nSQL execution failed: " . $dbh->errstr(). " SQL: \n\n----------------------\n".$sql."\n----------------------\n";
    
	$sql = "SELECT ID_FOTO,TS_IMPORT FROM fotos WHERE SHA256 = '".$sha256."'";
	$sth = $dbh->prepare($sql)
      or die 'SQL prepare statement failed: ' . $dbh->errstr(). " \nSQL: \n----------------------\n".$sql."\n----------------------\n";
    $sth->execute() or die 'SQL execution failed: ' . $dbh->errstr(). " SQL: \n----------------------\n".$sql."\n----------------------\n";
	if ( $sth->rows() < 1 ) {
        print "- Hmm.. strange. No image found for given checksum. Should not happen. \n";
    }
    else {
       my $ref 			 = $sth->fetchrow_hashref();
	   my $idFoto 		 = $ref->{'ID_FOTO'};
       my $tsImport      = $ref->{'TS_IMPORT'};
	   if ($tsImport < $ts) {
		  # Row exists in DB. Thumbnails are probably already existing.
	   } else {
		  &create_preview($file,$idFoto,$id_orientation,$imgWidth,$imgHeigth);
	   }
	}
}



# Create Preview Image
sub create_preview {
    my $file   		= shift;
	my $idFoto 		= shift;
	my $idOrientation = shift;
	my $width_orig  = shift;
	my $height_orig = shift;
	
	my $newSizeMedium = $cfg->param('PREVIEW_MEDIUM.MD_WIDTH')."x";
	my $newSizeSmall  = $cfg->param('PREVIEW_SMALL.SM_WIDTH')."x";
	
	if ($height_orig > $width_orig) {
		$newSizeMedium = "x".$cfg->param('PREVIEW_MEDIUM.MD_HEIGHT');
		$newSizeSmall  = "x".$cfg->param('PREVIEW_SMALL.SM_HEIGHT');
	}
	
	if ( $DBGLEVEL > 1 ) {
            print " - Creating previews [$newSizeMedium/$newSizeSmall] for $file ...";
    }
	
	my $folderMedium = $cfg->param('PREVIEW_MEDIUM.MD_EXPORT_FOLDER').sprintf("%04d",$idFoto >> 10);   # Bit shift right (roughly divide by 10)
	my $folderSmall  = $cfg->param('PREVIEW_SMALL.SM_EXPORT_FOLDER').sprintf("%04d",$idFoto >> 10);
	
	mkdir($folderMedium);
	mkdir($folderSmall);
	
	my $fileOutMedium = $folderMedium."/".sprintf("%08d",$idFoto).".jpg";
	my $fileOutSmall  = $folderSmall."/".sprintf("%08d",$idFoto).".jpg";
	
		my $flipflop = " "; # 1 Normal case
	
	# For jpeg not necessary
	#if 		($idOrientation == 2) { $flipflop = " -flop "; }
	#elsif 	($idOrientation == 3) { $flipflop = " -rotate 180 "; }
	#elsif 	($idOrientation == 4) { $flipflop = " -flip "; }
	#elsif 	($idOrientation == 5) { $flipflop = " -transverse "; }
	#elsif 	($idOrientation == 6) { $flipflop = " -rotate 90 "; }
	#elsif 	($idOrientation == 7) { $flipflop = " -rotate 90 -flop "; }
	#elsif 	($idOrientation == 8) { $flipflop = " -rotate 270 "; }
	
	
	my $cmd = 'magick convert "'.$file.'" -resize '.$newSizeMedium.' '.$flipflop.' -write "'.$fileOutMedium.'" -resize '.$newSizeSmall.'  "'.$fileOutSmall.'" '; 
	system($cmd);
	
	if ( $DBGLEVEL > 1 ) {
            print " done.\n";
    }
}


sub get_time_formatted {
    my $ts  = shift;
    my $dt  = DateTime->from_epoch( epoch => $ts, time_zone => $TIMEZONE );
    my $str = sprintf(
        "%02d.%02d.%04d %02d:%02d:%02d",
        $dt->day(),  $dt->month(),  $dt->year(),
        $dt->hour(), $dt->minute(), $dt->second()
    );
    return ($str);
}

