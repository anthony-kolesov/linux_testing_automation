package ARCLinux::GNU;

use strict;
use warnings;
use Data::Dumper;

my %default_keys = (
		    "git_root" => "git://github.com/foss-for-synopsys-dwc-arc-processors/",
		    "git_tree" => "cgen:arc_4_4-cgen-1_0-stable,binutils:arc_4_4-binutils-2_19-stable,gcc:arc_4_4-gcc-4_4-stable,gdb:arc_4_4-gdb-6_8-stable,newlib:arc_4_4-newlib-1_17-stable,uClibc:arc_4_4-uClibc-0_9_30-stable,toolchain:master"
);

sub new{
    my ($self,%hash) = @_;
    #my %params = ();
    #foreach my $key (@libs){
#	my ($lib,$version) = split(/:/,$key);
#	my $git = $hash{git_root}."/$lib";
#	$params{$git}=$version;
#    }
    return bless { %hash },$self;
}

sub updateConfigure{
    my $self = shift;
    my $addLine = shift;
    my $file_string = shift;
    my $workdir = shift;
    my @files = split(/,/,$file_string);
#    my $workdir = $self->{workdir};
    print "Withing GNU Moving to $workdir\n";
    chomp (my $cwd = `pwd`);
    chdir ($workdir);
    if ($? != 0 ){
	print "[ERROR] : Cannot move to directory $workdir\n";
    }
    print "Before for loop\n";
    foreach my $file (@files){
	chomp ($file);
	print "FIlE : $file\n";
	system("pwd");
	system ("ls -l $file");
	my $temp = $addLine;
	$temp =~ s/^-*|\s*-*//;
	print "Line to search $temp\n";
	if (`grep "$temp" $file`){
	    print "[WARN] : Line already exists so no adding\n";
	}else{
	    print "[INFO] : Adding lines $addLine\n";
	    $self->modify_elf_files($file,$addLine);
	}
    }
    print "moving back to $cwd\n";
    chdir($cwd);
    system("pwd");
}

sub modify_elf_files{
    my $self = shift;
    my $file = $_[0];
    my $addLine = $_[1];
    my $new_file = $file.".tmp";
    my $add = 0;
    open (FILE,$file) || die("Couldn't open file $file : $!\n");
    open (OUT,">$new_file") || die("Couldn't open file $new_file : $!\n");
    while (my $line = <FILE>){
        chomp ($line);
        if ($line =~ /if.*configure/){
            print OUT "$line\n";
            $add = 1;
            next;
        }
        if ($add == 1){
            print OUT "     $addLine \\\n";
            $add = 0;
        }
        print OUT "$line\n";
    }
    close (FILE);
    close (OUT);
    system("mv $new_file $file");
    system("chmod 755 $file");
}

sub comment_versions{
    my $self = shift;
    my $gnu_path = shift;
    my $toolchain = $gnu_path."/toolchain/build-all.sh";
    open (FL,$toolchain)||die("Couldn't open file $toolchain:$!\n");
    my $tmp = `basename $toolchain`;
    chomp ($tmp);
    open (TMP,">${tmp}.tmp")||die ("Couldn't open filefor writing ${tmp}.tmp : $!\n");

    my $comment = 0;
    while (my $line = <FL>){
	chomp ($line);
	if ($line =~ /arc-versions.sh/){
	    $comment = 1;
	}
	if ($comment){
	    if ($line =~ /^\s*fi\s*$|^\s*$/){
		$comment = 0;
	    }
	    $line =~ s/^/#/;
	}
	print TMP "$line\n";
    }
    close(TMP);
    system ("mv ${tmp}.tmp $toolchain");
}

sub build_gnu {
    my $self = shift;
    my $gnu = shift;
    my $gnu_install = shift;
    my $linux = shift;
    $gnu .= "/toolchain/";
    my $cwd = `pwd`;
    chomp ($cwd);
    chdir($gnu);
    my $cmd = "build-all.sh --linux-dir $linux --install-dir $gnu_install";
    print "Executing command $cmd under\n";
    system ("$cmd 2>&1");
    if ($? == 0){
	print "[INFO] : GNU Build was successful\n";
    }else{
	print "[INFO] : GNU Build Failed\n";
    }
    chdir($cwd);
}

1;
