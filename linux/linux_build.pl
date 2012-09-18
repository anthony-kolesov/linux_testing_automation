#!/usr/bin/perl

use strict;
use warnings;
use lib './lib';
#use lib '/u/vijayb/scripts/Automation/Linux/lib/';
use Getopt::Long;
use Mail::Sendmail;
use File::Path;
use Config::Tiny;
use Common::Checkout;
use Common::Utilities;
use ARCLinux::GNU;
use Data::Dumper;
use Env;
use Time::Local;

my %options = ();

if ($#ARGV < 0){
    usage();
    exit;
}

sub usage {
    print <<STDERR
	    $0 --config_file=<path to the config file>
	       --config <name of the config to run>	
	       --testconfig <name of the testconfigfile>
STDERR
}
GetOptions (\%options,
	    "config_file=s",
	    "config=s",
	    "testconfig=s",
);
our $cwd = `pwd`;
chomp ($cwd);

my %linux = ();
my %busybox = ();
my %ramfs = ();
my %gnu = ();
my %vm_board = ();
my %vm_mount = ();

#my $git_root = "";
#my $svn_root = "";
my $workdir = "";
#my $gnu_tree = "";
#my $linux_tree = "";
my @linux_tests = ();
my $gnu_install = "";
#my $busybox_tree = "";
my $archive_dir = "";
my $checkout = "";
my $hostname = `hostname`;
chomp ($hostname);
my $cfg = Config::Tiny->new();
my $cfg_hash = $cfg->read($options{config_file});
my $config = $cfg_hash->{$options{config}};


init($config);

if (exists $ENV{BUILD_NUMBER}){
    $workdir .= "/$ENV{BUILD_NUMBER}";
}else{
    $workdir .= "/console";
}
mkpath ($workdir) if (!-d $workdir);
$options{config_file} ||= $workdir."/automated_scripts/linux/Linux.cfg";
my $tests_config = $options{testconfig}||$workdir."/automated_scripts/linux/LinuxTests.cfg";
my $logfile = $workdir."/build.log";
my $status_file = $workdir."/.status";
open (STATUS,">>$status_file")||die("Couldn't open file $status_file for writing $!\n");
open (LOG,">$logfile")||die("Couldn't open log file $logfile : $!\n");

my $local_time = get_time();
my $end_time;
my $time_taken;
my %env = ();
my $start_date = $local_time;
$start_date =~ s/:.*$//;

print LOG "Process started at :  $local_time\n";
print LOG "=====================================================\n";
print LOG "[INFO] : Using config file : $options{config_file}\n";
print LOG "[INFO] : Using Tests Config : $tests_config\n";
print LOG "[INFO] : Building Config : $options{config}\n";
print LOG "[INFO] : Running from directory : $cwd\n";
if ((scalar(keys %env)) > 0 ){
    print "[INFO] : Setting Environments for following\n";
    print "-------------------------------------------------\n";
    foreach my $key (keys %env){
	set_env($key,$env{$key});
    }
    print "-------------------------------------------------\n";
}
#print "SVN ROOT : $svn_root\n";
#print "WORKDIR : $workdir\n";
#print "GNU TREE : $gnu_tree\n";
#print "GIT ROT : $git_root\n";
#print "Linux tree : $linux_tree\n";
#print "gnu tree : $gnu_tree\n";
if (exists $ENV{'WORKSPACE'}){
    $workdir = $ENV{'WORKSPACE'};
    print LOG "[INFO] : WORKSPACE from Jenkins : $ENV{WORKSPACE}\n";
}
print LOG "[HOSTNAME] : $hostname\n";
print LOG "[WORKSPACE] : $workdir\n";
#my $gnu_path = $workdir."/arc/";
my $gnu_path = $workdir;
my $busybox_dir = $workdir."/busybox/";
my $ramfs_dir = $workdir."/initramfs/";
my $linux_dir = $workdir."/linux/";
mkpath ($busybox_dir) if (!-d $busybox_dir);
mkpath ($ramfs_dir) if (! -d $ramfs_dir);
#print LOG "Using the following versions for building Linux : \n";

## Building GNU
print LOG "[INFO] : Building GNU with following versions of libraries\n";
print LOG "----------------------------------------------------------\n";

my $gnu_obj = ARCLinux::GNU->new();
#mkpath ($gnu_path) ||die("Couldn't create path : $gnu_path : $!\n") if (!-d $gnu_path);
#my %gnu_versions = %{$gnu_obj};
#foreach my $key (keys %gnu_versions){
#    my $key1 =$key;
#    $key1 =~ s/.*\///;
#    print LOG "$key1            : $gnu_versions{$key}\n";
#}
print LOG "----------------------------------------------------------\n";

my $co_obj = Common::Checkout->new();
#print Dumper ($gnu_obj);
#print "Executing checkout --- $gnu_path\n";
print STATUS "Check out::GNU Tool Chain::Started\n";
$local_time = get_time();
if (exists $gnu{'git_tree'}){
    tree_checkout($config->{'git_root'},$gnu{'git_tree'},$workdir,\*LOG);
}

if (exists $gnu{'git_link'}){
    link_checkout($gnu{'git_link'},$workdir,\*LOG);
}

if (exists $gnu{'svn_tree'}){
    tree_checkout($config->{'svn_root'},$gnu{'svn_tree'},$workdir,\*LOG);
}

if (exists $gnu{'svn_link'}){
    link_checkout($gnu{'svn_link'},$workdir,\*LOG);
}
$local_time="2012-09-17:01:38:58";
$end_time = get_time();
$time_taken = get_time_taken($local_time,$end_time);

print STATUS "Check out::GNU Tool Chain::Done\n";
print LOG "[INFO] : Time taken for checkout of GNU Tool chain :: $time_taken\n";
print STATUS "Check out::Linux::Started\n";
$local_time = get_time();
if (exists $linux{'git_tree'}){
    tree_checkout($config->{'git_root'},$linux{'git_tree'},$workdir,\*LOG);
}

if (exists $linux{'git_link'}){
    link_checkout($linux{'git_link'},$workdir,\*LOG);
}

if (exists $linux{'svn_link'}){
    link_checkout($linux{'svn_link'},$workdir,\*LOG);
}

if (exists $linux{'svn_tree'}){
    tree_checkout($config->{'svn_root'},$linux{'svn_tree'},$workdir,\*LOG);
}
$end_time = get_time();
$time_taken = get_time_taken($local_time,$end_time);
print LOG "[INFO] : Time Taken for checking out Linux : $time_taken\n";
print STATUS "Check out::Linux::Done\n";
print STATUS "Building::GNU Tool Chain::Started\n";
$local_time = get_time();
if (exists $gnu{configure}){
    if (exists $gnu{configure_files}){
	$gnu_obj->updateConfigure($config->{gnu_configure},$config->{gnu_configure_files},$workdir);
    }else{
        print LOG "[ERROR] : Please specify option gnu_configure_files w.r.t gnu_configure\n";
        mail_error("Input Error","Failed",\*LOG);
        exit;
    }
}
print LOG "[INFO] : Building GNU\n";
$gnu_install = $workdir."/gnu_install/";
$gnu_obj->comment_versions($gnu_path);
$gnu_obj->build_gnu($gnu_path,$gnu_install,$linux_dir);
$end_time = get_time();
$time_taken = get_time_taken($local_time,$end_time);
print STATUS "Building::GNU Tool Chain::Done\n";
print LOG "[INFO] : Time Taken for Building GNU : $time_taken\n";
print LOG "[INFO] : Updating the PATH variable with GNU path, $gnu_install/\n";
print LOG "-----------------------------------------------------------------\n";
set_env("PATH","$gnu_install/bin");
set_env("PATH","$gnu_install/arc-elf32/bin");
set_env("PATH","$gnu_install/arc-linux-uclibc/bin");
mkpath ($ramfs_dir) if (!-d $ramfs_dir);
$local_time = get_time();
if (exists $ramfs{'svn_tree'}){
    tree_checkout($config->{'svn_root'},$ramfs{'svn_tree'},$ramfs_dir,\*LOG);
}

if (exists $ramfs{'svn_link'}){
    link_checkout($ramfs{'svn_link'},$ramfs_dir,\*LOG);
}

if (exists $ramfs{'git_link'}){
    link_checkout($ramfs{'git_link'},$ramfs_dir,\*LOG);
}

if (exists $ramfs{'git_tree'}){
    tree_checkout($config->{'git_root'},$ramfs{'git_tree'},$ramfs_dir,\*LOG);
}
#if ($checkout){
#    print LOG "[INFO] : Checkout of ramfs $ramfs_link to $ramfs_dir\n";
#    $co_obj->checkout(workdir=>$ramfs_dir,$ramfs_link=>undef);
#    print LOG "[INFO] : Extract initramfs --- $ramfs_dir\n";
    print LOG "[INFO] : Extracting $ramfs{'file'} from $ramfs_dir\n";
    extract_initramfs($ramfs_dir,$ramfs{'file'});
#}
#my ($bb_link,$bb_version) = split(/::/,$config->{busybox_git_link}) ;
$end_time=get_time();
$time_taken = get_time_taken($local_time,$end_time);
print LOG "[INFO] : Time Taken for checking out arc_initramfs :: $time_taken\n";
print STATUS "Checkout::arc_initramfs::Done\n";
print STATUS "Checkout::Busy Box::Started\n";
if (exists $busybox{'svn_tree'}){
    tree_checkout($config->{'svn_root'},$busybox{'svn_tree'},$workdir,\*LOG);
}

if (exists $busybox{'svn_link'}){
    link_checkout($busybox{'svn_link'},$workdir,\*LOG);
}

if (exists $busybox{'git_link'}){
    link_checkout($busybox{'git_link'},$workdir,\*LOG);
}

if (exists $busybox{'git_tree'}){
    tree_checkout($config->{'git_root'},$busybox{'git_tree'},$workdir,\*LOG);
}
$end_time=get_time();
$time_taken = get_time_taken($local_time,$end_time);
print STATUS "Checkout::Busy Box::Done\n";
print LOG "[INFO] : Time taken for checking out busybox :: $time_taken\n";

#if ($checkout){
#    print LOG "[INFO] : Checking out buxybox\n";
#    $co_obj->checkout(workdir=>$workdir,$bb_link=>$bb_version);
#    $busybox_dir .= "/busybox";
#}
#my $bb_changes = $config->{busybox_changeconfig};
print LOG "[INFO] : Building Busybox\n";
$local_time=get_time();
print STATUS "Building::Busy Box::Started\n";
build_busybox("$workdir/busybox");
print STATUS "Building::Busy Box::Done\n";
$end_time=get_time();
$time_taken = get_time_taken($local_time,$end_time);
print LOG "[INFO] : Time taken for completing Busy Box :: $time_taken\n";
my $vm_mount = $config->{vm_mount};
@linux_tests = split(/,/,$config->{runtests});
my $test_config=$cfg->read($tests_config);
print "[INFO] : Adding lines to rcS file which would be run\n";
init_add_lines_rcs("$workdir/arc_initramfs/etc/init.d/rcS",$vm_mount);
foreach my $test (@linux_tests){
    print LOG "[INFO] : Adding lines to rcS for $test\n";
    get_add_lines_rcs($vm_mount,$test,$test_config);
    print LOG "[INFO] : Building Linux Test : $test\n";
    print LOG "[INFO] : Started at ",&get_time,"\n";
    print STATUS "Linux Test-${test}::Building::Started\n";
    build_linux_tests($vm_mount,$test,$test_config);
    print STATUS "Linux Test-${test}::Building::Done\n";
}

open (RCS,">>$workdir/arc_initramfs/etc/init.d/rcS")||die("Couldn't open file $workdir/arc_initramfs/etc/init.d/rcS : $!\n");
print RCS "kill 1";
my $linux_cfg = $config->{linux_buildconfig};
print LOG "[INFO] : Building Linux\n";
build_linux($linux_dir);
print STATUS "Loading Linux::Loading::Started\n";
load_linux("$linux_dir/vmlinux");
print STATUS "Loading Linux::Loading::Done\n";
foreach my $test (@linux_tests){
    collect_report($test_config,$test);
}
print STATUS "Completed Successfully\n";
my $alldone = $workdir."/alldone";
system("touch $alldone");

mail_error("Linux Tests Completed","Build Successful");

sub init{
    my $config = shift;
    my %hash = %{$config};
    foreach my $key (keys %hash){
	chomp ($key);
	my $value = $hash{$key};
	if ( $key =~ /^ENV_(.*?)$/ ){                            
	    #set_env($1,$value);                                
	    $env{$1}=$value;                                
	}          
	if ( $key eq "workdir" ){                                
	    $workdir = $value;                                   
	}                                                        
	if ( $key =~ /^busybox_(.*?)$/ ){                        
	    $busybox{$1}=$value;                                 
	}                                                        
	if ($key =~ /^linux_(.*?)$/){                            
	    $linux{$1} = $value;                                 
	}                                                        
	if ($key =~ /^gnu_(.*?)$/){                              
	    $gnu{$1} = $value;                                   
	}                                                        
	if ($key =~ /^arc_initramfs_(.*?)$/){                    
	    $ramfs{$1} = $value;                                 
	}                                                        
	if ($key =~ /^vm_board/){                                
	    $value =~ /(.*?)\@(.*?):(.*?)$/;                     
	    $vm_board{user} = $1;                                
	    $vm_board{ip} = $2;                                  
	    $vm_board{path} = $3                                 
	}                                                        
	if ($key =~ /^vm_mount/){                                
	    $value =~ /(.*?)\@(.*?):(.*?)$/;                     
	    $vm_mount{user} = $1;                                
	    $vm_mount{ip} = $2;                                  
	    $vm_mount{path} = $3                                 
	}                                                        
    }
    if (exists $hash{'xbf_path'}){
	$vm_mount{'xbf_path'} = $hash{'xbf_path'};
    }
    $vm_mount{'blast_cmd'} = $hash{'blast_cmd'} if (exists $hash{'blast_cmd'});
    $vm_mount{'run_cmd'} = $hash{'run_cmd'} if (exists $hash{'blast_cmd'});
    if (exists $ENV{WORKSPACE}){
	$workdir = $ENV{WORKSPACE};
    }else{
	$workdir = $hash{workdir};
    }
    $checkout = $config->{checkout};
    $archive_dir = $config->{archive_dir};
}

sub updateConfig {
    my ($cfg,$changes) = @_;
    open (CHG,$changes)||die("Couldn't open file $changes : $!\n");
    my %vars = ();
    while (my $line = <CHG>){
	chomp ($line);	
	$line =~ s/\s*$//;
	next if ($line =~ /^\s*#/);
	next if ($line =~ /^\s*$/);
	my ($var,$val)=split(/=/,$line);
	$vars{$var}=$val;
    }
    close(CHG);
    open (CFG,$cfg)||die("Couldn't open file $cfg\n");
    open (TMP,">${cfg}.tmp")||die("Couldn't open file ${cfg}.tmp : $!\n");
    while (my $line = <CFG>){
	chomp ($line);
	if ($line =~ /^#|^\s*#|^\s*$/){
	    print TMP "$line\n";
	    next;
	}
	if ($line =~ /(.*?)=(.*?)$/){
	    if (exists $vars{$1}){
		print LOG "$1 : $2 -> $vars{$1}\n";
		print TMP "$1=$vars{$1}\n";
		next;
	    }
	}
	print TMP "$line\n";
    }
    system("mv ${cfg}.tmp $cfg");
    check_status("Move of ${cfg}.tmp -> $cfg");
}

sub set_env {
    my ($env,$path) = @_;
    $ENV{$env} .=":$path";
    print LOG "[ENVIRONMENT] : -> $env = $ENV{$env}\n";
}
sub build_busybox {
    my $dir = $_[0];
    my $bb_log = $workdir."/busybox_build.log";
    chdir($dir);
    print LOG "[PATH] : $ENV{PATH}\n";
    print "[PATH] : $ENV{PATH}\n";
    print LOG "[INFO] : $ENV{LD_LIBRARY_PATH}\n";
    print "[LD_LIBRARY_PATH] : $ENV{LD_LIBRARY_PATH}\n";
    print LOG "[INFO] : make $busybox{buildconfig}\n";
    system("make $busybox{buildconfig} > $bb_log 2>&1");
    check_status("Busybox : make $busybox{buildconfig}");
    if (exists $busybox{changeconfig}){
        print LOG "[INFO] : Updating busybox config file\n";
	print LOG "-----------------------------------------------------------------\n";
	updateConfig(".config",$busybox{changeconfig});
    }
    print LOG "[COMMAND] : make \n";
    system("make >>$bb_log 2>&1");
    check_status("Busybox build : make");
    print LOG "[COMMAND] : make install\n";
    system("make install >>$bb_log 2>&1");
    check_status("Busybox install : install");
    print LOG "[COMMAND] : cp busybox_unstripped $gnu_path/arc_initramfs/bin/busybox\n";
    system("cp busybox_unstripped $gnu_path/arc_initramfs/bin/busybox >>$bb_log 2>&1");
    check_status("copying of busybox_unstripped");
}

sub build_linux{
    my $dir = $_[0];
    my $cfg = $_[1];
    chomp (my $cwd = `pwd`);
    my $linux_log = $workdir."/linux.log";
    chdir($dir);
    check_status("Moving to directory $dir");
    print LOG "[COMMAND] : make ARCH=arc $linux{buildconfig}\n";
    system ("make ARCH=arc $linux{buildconfig} >$linux_log 2>&1");
    check_status("make ARCH=arc $linux{buildconfig}");
    #my $linux_changes = $config->{linux_changeconfig};
    if (exists $linux{'changeconfig'}){
	print LOG "[INFO] : Updating Linux Config File : $linux{changeconfig}\n";
	updateConfig(".config",$linux{'changeconfig'});
    }
    print LOG "[INFO] : make ARCH=arc\n";
    system("make ARCH=arc >>$linux_log 2>&1");
    check_status("make build");
    chdir($cwd);
}
    
sub extract_initramfs{
    my $dir = $_[0];
    my $file = $_[1];
    chomp (my $cwd = `pwd`);
    chdir($dir);
    my $tar_file = `find -name "$file"`;
    chomp ($tar_file);
    print LOG "[INFO] : Extracting tar file -> $tar_file\n";
    mkdir ("temp",0777) if (!-d "temp");
    print LOG "[CMD] : tar -xzf $tar_file -C temp/\n";
    system("tar -xzf $tar_file -C temp/ 2>&1");
    check_status("Extraction of tar file $tar_file");
    my $arc_dir = `find temp/ -type d -name "arc_initramfs"`;
    chomp ($arc_dir);
    print LOG "[INFO] : Moving $arc_dir -> $workdir\n";
    system ("rm -rf $workdir/arc_initramfs") if (-d "$workdir/arc_initramfs");
    system("mv $arc_dir $gnu_path");
    chdir($cwd);
}

sub init_add_lines_rcs{
    my $file = $_[0];
    my $mount = $_[1];
    $mount =~ s/.*?\@//;
    open (RCS,">>$file")||die("Couldn't open file $file for appending : $!\n");
    print RCS "\n\n";
    print RCS "mkdir /nfs/tests/\n";
    print RCS "if [ \$\? != 0 ]; then\n";
    print RCS "   echo \"Creation of directory /nfs/tests/ failed\"\n";
    print RCS "fi\n\n";
    print RCS "mount -t nfs -o nolock $mount /nfs/tests/\n";
    print RCS "if [ \$\? != 0 ]; then\n";
    print RCS "   echo \"Mounting of $mount to /nfs/tests/ failed\"\n";
    print RCS "fi\n\n";
    close(RCS);
}

sub get_add_lines_rcs{
    my $vm = $_[0];
    my $test = $_[1];
    my $cfg = $_[2];
    my @cmds = split(/::/,$cfg->{$test}->{cmd_trg});
    my $status_file = $cfg->{$test}->{status_file};
    my $cur_time = get_time();
    my $local_archive = "/nfs/tests/archives/$start_date";
    $cur_time =~ s/:.*$//;
    my $test_log = $test."_".$cur_time;
    my $file = $gnu_path."/arc_initramfs/etc/init.d/rcS";
    open (RCS,">>$file")||die("Couldn't open file $file for appending : $!\n");
    my ($user,$mount) = split(/@/,$vm);
    print RCS "cd  /nfs/tests/$test\n";
    if ($cfg->{$test}->{copy_local} eq "yes"){
	print RCS "mkdir -p /mnt/tests\n";
	print RCS "if [ \$\? != 0 ]; then\n";
	print RCS " echo \"Failed creating directory /mnt/tests\"\n";
	print RCS "fi\n";
	print RCS "cp -rd /nfs/tests/$test /mnt/tests/";
        print RCS "if [ \$\? != 0 ]; then\n";
        print RCS " echo \"Failed copying /nfs/tests -> /mnt/tests\"\n";
        print RCS "fi\n";
	print RCS "cd /mnt/tests/$test\n";
        print RCS "if [ \$\? != 0 ]; then\n";
        print RCS " echo \"Failed moving to /mnt/tests\"\n";
        print RCS "fi\n";
    }
    foreach my $cmd (@cmds){
	$cmd =~ s/logfile/$test_log/;
	print RCS "$cmd\n";
        print RCS "if [ \$\? != 0 ]; then\n";
        print RCS " echo \"Failed Running command $cmd\"\n";
        print RCS "fi\n";

    }
    my @archives = split(/::/,$cfg->{$test}->{archive_files});
    print RCS "if [ ! -d $local_archive ]; then\n";
    print RCS "	mkdir -p $local_archive\n";
    print RCS "fi\n";
    foreach my $arch (@archives){
	chomp ($arch);
	$arch =~ s/logfile/$test_log/;
	print RCS "if [ -d $arch ]; then\n";
	print RCS " cp -rd $arch $local_archive\n";
	print RCS "else\n";
	print RCS " cp $arch $local_archive\n";
	print RCS "fi\n";
    }
}

sub load_linux{
    my $linux = $_[0];
    my ($vm,$partition) = split(/:/,$config->{vm_board});
    my $xbf = $config->{xbf_path};
    my $blast_cmd = $config->{blast_cmd};
    my $run_cmd = $config->{run_cmd};
    my $license = $config->{LM_LICENSE_FILE};
    my $xbf_path = $xbf;
    my $load_log = $workdir."/linux_load.log";
    $xbf_path =~ s/\/cygdrive\///;
    $xbf_path =~ s/^c\//C:\\/;
    $xbf_path =~ s/\//\\/;
    while(1){
	my $lock = check_lock($vm,$partition);
	if ($lock){
	    print STATUS "Sleeping::Old Process Running\n";
	    system("sleep 600");
	}else{
	    last;
	}
    }
    
    edit_lock($vm,$partition,1);
    print LOG "[INFO] : Copying vmlinux to $vm under $partition\n";
    print LOG "[INFO] : /usr/bin/scp $linux $config->{vm_board}\n";
    system("/usr/bin/scp $linux $config->{vm_board}");
    check_status("scp $linux -> $config->{vm_board}");
    print LOG "[INFO] : Copying XBF to $vm\n";
    print LOG "[INFO] : /usr/bin/scp $xbf $config->{vm_board}\n";
    system("/usr/bin/scp $xbf $config->{vm_board}");
    check_status("scp $xbf -> $config->{vm_board}");
    $blast_cmd .= " -blast=$xbf_path ";
    if ($partition =~ /\/cygdrive\//){
	$partition =~ s/\/cygdrive\///;
	$partition =~ s/^c\//C:\\/;
	$partition =~ s/\//\\/;
    }
    my $script_file = "/tmp/load_linux.sh";
    open (LD,">$script_file")||die("Couldn't open file $script_file\n");
    print LD "#\!/bin/sh\n";
    print LD "echo \"Loading linux\"\n\n";
    print LD "echo \"$run_cmd  $linux\"\n";
    print LD "cmd <<EOF\n";
   # print LD "$blast_cmd\n";
   # print LD "if [ \$\? == 0 ]; then\n";
   # print LD "	echo \"Blasting was successful\"\n";
   # print LD "else\n";
   # print LD "	echo \"Blasting XBF $xbf failed\n";
   # print LD "fi\n";
    print LD "set Path=\%Path\%;C:\\ARC\\mwdt201203rc2v2\\MetaWare\\arc\\bin;C:\\Program Files\\teraterm\n";
    print LD "set LM_LICENSE_FILE=3457\@sp-flexnet01;3457\@sp-flexnet02;3457\@de02-lic4.internal.synopsys.com;3457\@de02-lic5.internal.synopsys.com;26585\@us01_lic6\n";
    print LD "ttermpro /BAUD=115200\n";
    print LD "$run_cmd  $partition\\vmlinux\n";
   # print LD "if [ \$\? == 0 ];then\n";
   # print LD "	echo \"Running command $run_cmd was successful\"\n";
   # print LD "fi\n";
   # print LD "else\n";
   # print LD "	echo \"Run Failed\"\n";
   # print LD "fi\n";
    print LD "EOF\n";
    close(LD);
    print LOG "[INFO] : Restarting VM\n";
    restart_vm($vm);
    print LOG "[INFO] : Copying script to local machine : $vm\n";
    print LOG "[INFO] : /usr/bin/scp $script_file $config->{vm_board}\n";
    print LOG "[COMMAND] : ssh $vm load_linux.sh\n";
    chmod(0755,"$script_file");
    print("ssh $vm load_linux.sh\n");
    system("scp $script_file ${vm}:");
    check_status("scp $script_file -> ${vm}:");
    system("ssh $vm 'sh load_linux.sh' >>$load_log 2>&1");
    check_status("loading linux");
}

sub edit_lock{
    my $vm = $_[0];
    my $part = $_[1];
    my $add = $_[2];
    my $lock = $part."/.lock";
    if ($add){
	system("ssh $vm \"touch $lock\"");
    }else{
	system("ssh $vm \"rm $lock\"");
    }
}

sub check_lock{
    my $vm = $_[0];
    my $part = $_[1];

    my $lock = $part."/.lock";
    system ("ssh $vm \"ls $lock\"");
    if ($? == 0){
	return 1;
    }else{
	return 0;
    }
}
sub restart_vm {
    my $login = $_[0];
    print "Executing : ssh $login 'shutdown -r 0'";
    system("ssh $login 'shutdown -r 0' 2>&1");
    my $threshold = 900;
    my $sleep_time = 0;
    system("sleep 200");
    $sleep_time += 200;
    while (1){
	system("ssh $login 'ls'");
	if ($? == 0){
	    print "Machine is up and running\n";
	    last;
	}else{
	    print "Machine is still booting\n";
	    system("sleep 100");
	    $sleep_time += 100;
	}
	if ($sleep_time > $threshold){
	    print "Machine rebot of $login failed\n";
	}
    }
}

sub build_linux_tests{
    my $vm = $_[0];
    my $test = $_[1];
    my $cfg = $_[2];
#    my $vm_hash = %{$vm_cfg};
    my $source_link = $cfg->{$test}->{source};
    my @cmds = split(/::/,$cfg->{$test}->{cmd_bld});
    my ($login,$partition) = split(/:/,$vm);
    my $script_file = "/tmp/build_${test}.sh";
    print "[INFO] : COpying $gnu_install to remote machine $vm\n";
    print LOG "[INFO] : COpying $gnu_install to remote machine $vm\n";
    my $basename = `basename $gnu_install`;
    chomp ($basename);
    print ("ssh -t $login 'rm -rf $partition/$basename'\n");
    system("ssh -t $login 'rm -rf $partition/$basename'");
    #system( "scp -rd $gnu_install ${login}:$partition");
    #my $basename = `basename $gnu_install`;
    #chomp ($basename);
    open (LTP,">$script_file")||die("Couldn't open file $script_file : $!\n");
    print LTP "#\!/usr/bin/sh\n";
    print LTP "echo \"Checkint out source for $test\"\n";
    print LTP "if [ -d $partition/$test ]; then\n";
    print LTP "	echo \"Deleting $partition/$test\"\n";
    print LTP "	sudo rm -rf $partition/$test\n";
    print LTP "fi\n";
    print LTP "mkdir $partition/$test\n";
    print LTP "cd $partition/$test\n";
    if ( $source_link =~ /svn/ ){
        print LTP "svn co --username 'vijayb' --password 'AnuR\@j15' $source_link .\n";
    }elsif ( $source_link =~ /git/ ){
	my ($link,$version) = split (/::/,$source_link);
	print LTP "git clone $link .\n";
	print LTP "git checkout $version\n";
    }else {
	print LOG "[ERROR] : Only SVN and GIT are supported The Link $source_link doesn't seem to be any of these repositories\n";
	mail_error("$test link not correct","Failed",\*LOG);
    }
    print LTP "echo \"Updating PATH variable with ${partition}/$basename\"\n";
    #print LTP "export PATH=\${PATH}:$partition/$basename/bin:$partition/$basename/arc-elf32/bin:$partition/$basename/arc-linux-uclibc/bin\n";
    print LTP "export PATH=\${PATH}:/home/user1/vijayb/TESTING/manual/gnu_install/bin:/home/user1/vijayb/TESTING/manual/gnu_install/arc-elf32/bin:/home/user1/vijayb/TESTING/manual/gnu_install/arc-linux-uclibc/bin\n";
    print LTP "echo \$PATH\n";
    foreach my $cmd (@cmds){
	print LTP "$cmd\n";
	print LTP "if [ \$\? == 0 ]; then\n";
	print LTP " echo \"Execution of $cmd passed\"\n";
	print LTP "fi\n";
	print LTP "\n";
    }
    #print LTP "sudo rm -rf $partition/$test/runtest/pty\n";
    print LTP "sed -i -rs \"s/^/#/\" $partition/$test/runtest/pty\n";
    chmod(0755,"$script_file");
#    print LOG "[CMD] : ssh $login $script_file\n";
    print LOG "[INFO] : Copying script file $script_file to $partition\n";
    print "[CMD] : scp $script_file ${login}:$partition\n ";
    system("scp $script_file ${login}:$partition ");
    check_status("scp $script_file ${login}:$partition ");
    print LOG "[INFO] : ssh -t $login 'sh $partition/build_${test}.sh'\n";
    system("ssh -t $login 'sh $partition/build_${test}.sh'");
    check_status("Building $test");
    close(LTP);
}

sub get_time {

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

$year += 1900;
$mon += 1;
my $newyear = sprintf("%04d",$year);
my $month = sprintf ("%02d",$mon);
my $day = sprintf ("%02d",$mday);
my $hr = sprintf ("%02d",$hour);
$min = sprintf ("%02d",$min);
$sec = sprintf ("%02d",$sec);
my $string = $year."-".$month."-".$day.":".$hr.":".$min.":".$sec;
return $string;
}

sub check_status{
    my $cmd = $_[0];
    if ($? == 0 ){
        print LOG "[INFO] : Execution of $cmd : Passed\n";
    }else{
        print LOG "[ERROR] : Execution of $cmd : Failed\n";
	my $fail = $workdir."/failed";
	system("touch $fail");
	mail_error("$cmd","Failed");
	edit_lock("$vm_board{user}\@$vm_board{ip}",$vm_board{path});
	exit;
    }
}

sub tree_checkout {
    my ($root,$tree,$workdir,$loghandle) = @_;
    my @libs = split(/,/,$tree);
    foreach my $lib (@libs){
        chomp ($lib);
        my ($bin,$version) = split(/::/,$lib);
	print $loghandle "$bin : $version\n";
        my $git_link = $root;
        $git_link =~ s/\/\s*$//;
        $git_link .= "/$bin";
	print "GIT LINK : $git_link\n";
        my $clone_path = $workdir."/$bin";
	print "CLONE PATH : $clone_path\n";
        if ($checkout){
	    print $loghandle "[INFO] : Cloning $git_link -> $clone_path\n";
	    if ($git_link =~ /git/){
		$co_obj->git_clone($clone_path,$git_link,$loghandle);
	    }elsif ($git_link =~ /subversion/){
		$co_obj->svn_checkout($clone_path,$git_link,$loghandle);
	    }else {
		print $loghandle "[ERROR] : Currently only Git and SVN repositories are supported.. For further details please mail 'vijayb\@synopsys.com'\n";
		mail_error("Checkout Failed","Link not related to git or subversion",$loghandle);
		exit;
	    }
	}
        $co_obj->git_checkout($clone_path,$version,$loghandle) if ($git_link =~ /git/);
    }
}

sub link_checkout {
    my ($link,$workdir,$loghandle) = @_;
    my @links = split(/,/,$link);
    foreach my $string (@links){
        chomp ($string);
        my ($git_link,$version) = split(/::/,$string);
        chomp (my $basename = `basename $git_link`);
	$basename =~ s/\.git\s*$//;
        my $clone_path = $workdir."/$basename";
        if ($checkout){
            if ($git_link =~ /git/){
                $co_obj->git_clone($clone_path,$git_link,$loghandle);
            }elsif ($git_link =~ /subversion/){
                $co_obj->svn_checkout($clone_path,$git_link,$loghandle);
            }else {
                mail_error("Checkout Failed","Link not related to git or subversion");
                exit;
            }
        }
        $co_obj->git_checkout($clone_path,$version,$loghandle) if ($git_link =~ /git/);
    }
}

sub collect_report{
    my $tests_cfg = $_[0];
    my $test = $_[1];
    my ($login,$path) = split(/:/,$config->{vm_mount});
    my $status_file = $tests_cfg->{$test}->{status_file};
    my @patterns = split(/,/,$tests_cfg->{$test}->{pattern});
    $status_file =~ s/logfile/$start_date/;
    $status_file =~ s/.*\///;
    print "Sizze of patterns",scalar(@patterns),"\n";
    print LOG "[INFO] : Copying files from $login:$path/archives/$start_date\n";
    print "Collecting Reports\n";
#    mkpath ("$archive_dir/$start_date") if (!-d "$archive_dir/$start_date");
#    system("scp -rd $login:$path/archives/$start_date $archive_dir");
    check_status("Copying files from $login:$path/archives/$start_date","Failed");
    my $read_file = $archive_dir."/".$start_date."/ltp_".$status_file;
    print "Reading file : $read_file\n";
    print LOG "[INFO] : Reading status file $read_file\n";
    print LOG "[TEST RESULTS] : $test\n";
    print LOG "-------------------------------------\n";
    my @print_lines = ();
    foreach my $pattern (@patterns){
	chomp ($pattern);
	print "PATTER : $pattern $read_file\n";
	print "grep $pattern $read_file\n";
	my @lines = `grep \"$pattern\" $read_file`;
	push @print_lines,@lines;
    }
    print "Out on scalar",scalar(@print_lines),"\n";
    foreach my $line (@print_lines){
	print "Line : $line\n";
	chomp ($line);
	print LOG "$line\n";
    }
    print LOG "------------END-----------\n";
    system("sleep 5");
    print "Returning to function\n";
}
sub mail_error{
    my $subject = $_[0];
    my $status = $_[1];
    my @audience = split(/,/,$config->{audience});
    my @to = ();
    my $from = "vijayb\@synopsys.com";
    foreach my $audience (@audience){
	chomp ($audience);
	if ($audience =~ /\@.*\.com/){
	    push @to,$audience;
	}else{
	    my $to_string = $audience."\@synopsys.com";
	    push @to,$to_string;
	}
    }
    my $to = join(",",@to);
    my $mail_subject = "$status : Linux Build : ";
    $mail_subject .= $subject;
    my %mail = ( To        => "$to",
		 From      => "$from",
		 Subject   => "$mail_subject",
		 "Content-type" => "text/html",
		);
    open (OUT,$logfile)||die("Couldn't open file : $logfile : $!\n");
    while (<OUT>){
	chomp ($_);
	$mail{Message} .= $_."<br>";
    }
    sendmail(%mail);
}

sub get_time_taken{
    my $start = $_[0];
    my $end = $_[1];
    $start =~ /(.*?)-(.*?)-(.*?):(.*?):(.*?):(.*?)$/;
    my $start_local = timelocal($6,$5,$4,$3,$2,$1);
    $end =~ /(.*?)-(.*?)-(.*?):(.*?):(.*?):(.*?)$/;
    my $end_local = timelocal($6,$5,$4,$3,$2,$1);
    my $time = $end_local - $start_local;

    my $hours = int ($time / 3600);
    $time = $time % 3600;

    my $minutes = int ($time / 60);
    $time = $time % 60;

    my $seconds = $time;

    my $string = "$hours:$minutes:$seconds";
    return $string;
}
