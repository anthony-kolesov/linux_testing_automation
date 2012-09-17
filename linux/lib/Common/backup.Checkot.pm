package Common::Checkout;

use strict;
use warnings;
use Cwd;
use Data::Dumper;

my $git_clone = "git clone ";
my $git_co = "git checkout ";
my $svn_co = "svn co --username 'vijayb' --password 'AnuR\@j15' ";

sub new{
    my ($self,%hash) = @_;
#    if ($hash{repo} eq "git"){
#	$hash{cmd} = "git clone ";
#    }
#    if ($hash{repo} eq "svn"){
#	$hash{cmd} = "svn co --username 'vijayb' --password 'AnuR\@j28' "
#    }
#    foreach my $key (keys %hash){
#	$params{$key}=$hash{$key};
#    }
    return bless {%hash},$self;
}

sub checkout {
    my ($self,%hash) = @_;
    print "HASH in checkout\n";
    print Dumper (\%hash);
    my $workdir = $hash{workdir};
    print "WORKDIR : $workdir\n";
    delete $hash{workdir};
    foreach my $repo (keys %hash){
	if ($repo =~ /git/){
	    $self->_git_checkout($workdir,$repo,$hash{$repo});
	}elsif ($repo =~ /subversion/){
	    $self->_svn_checkout($workdir,$repo);
	}else{
	    print "[ERROR] : Unable to get the repository, only 'Github' and 'subversion' are supported $repo\n";
	    exit;
	}
    }
}

sub _git_checkout{
    my $self = shift;
    my $workdir = shift;
    my $repo = shift;
    my $version = shift;
#    my %hash = %{$self};
    print "WORK DIR : $workdir\n";
    chomp (my $cwd = `pwd`);
    if (-d $workdir){
	chdir($workdir);
	if ( $? != 0 ){
	    print "Failed moving to directory $workdir : $!\n";
	}
    }else{
	print "Directory $workdir does not exists \n";
	exit;
    }
   #my $cmd = $hash{cmd};
    #my $cmd = "git clone ";
    my $basename = $repo;
    $basename =~ s/.*\///;
    $basename =~ s/\.git\s*$//;
    $workdir .= "/$basename";
    print ("$git_clone $repo $workdir\n");
    #system("pwd");
    #system ("$git_clone $repo $workdir 2>&1");
    if ( $? == 0 ){
        print "[INFO] : GIT CLONE of $repo was successful\n";
    }else {
        print "[ERROR] : GIT CLONE of $repo failed\n";
        exit;
    }
    chdir ($workdir);
    if ($version ne "master") {
	system("$git_co $version");
	if ( $? == 0 ){
	    print "[INFO] : GIT checkout of $repo was successful\n";
	}else {
	    print "[[ERROR] : GIT Checkout of $repo failed\n";
	    exit;
	}
    }
    chdir($cwd);
}

sub _svn_checkout {
    my $self = shift;
    my $workdir = shift;
    my $svn = shift;
    my $basename = $svn;
    $basename =~ s/\/trunk\/*\s*$//;
    $basename =~ s/.*\///;
    chomp (my $cwd = `pwd`);
    chdir($workdir);
    mkdir($basename,0777);
    chdir($basename);
    if ($? != 0){
	print "[ERROR] : Moving to directory $basename Failed. $!\n";
    }
    print "$svn_co $svn\n";
    system("pwd");
    system ("$svn_co $svn 2>&1");
    chdir($cwd);
}
1;
