package Common::Checkout;

use strict;
use warnings;
use Cwd;
use Data::Dumper;
use File::Path;

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

sub git_clone{
    my $self = shift;
    my $workdir = shift;
    my $repo = shift;
    my $fh = shift;
#    my %hash = %{$self};
    print "WORK DIR : $workdir\n";
   #my $cmd = $hash{cmd};
    #my $cmd = "git clone ";
    print "$git_clone $repo $workdir\n";
    print $fh "[CMD] : $git_clone $repo $workdir\n";
    #system("pwd");
    if (-d $workdir){
	print $fh "[INFO] : Deleting old directory $workdir\n";
	rmtree($workdir);
    }
    system ("$git_clone $repo $workdir 2>&1");
    if ( $? == 0 ){
        print $fh "[INFO] : GIT CLONE of $repo was successful\n";
    }else {
        print $fh "[ERROR] : GIT CLONE of $repo failed\n";
        exit;
    }
}

sub git_checkout{
    my $self = shift;
    my $workdir = shift;
    my $version = shift;
    my $fh = shift;
    chdir ($workdir);
    if ($version ne "master") {
	system("$git_co $version");
	if ( $? == 0 ){
	    print $fh "[INFO] : GIT checkout of $version under $workdir was successful\n";
	}else {
	    print $fh "[ERROR] : GIT Checkout of $version under $workdir failed\n";
	    exit;
	}
    }
}

sub svn_checkout {
    my $self = shift;
    my $workdir = shift;
    my $svn = shift;
    my $fh = shift;
    print $fh "$svn_co $svn\n";
    system ("$svn_co $svn $workdir  2>&1");
        if ( $? == 0 ){
            print $fh "[INFO] : SVN checkout of $svn_co under $workdir was successful\n";
        }else {
            print $fh "[ERROR] : SVN Checkout of $svn under $workdir failed\n";
            exit;
        }

}
1;
