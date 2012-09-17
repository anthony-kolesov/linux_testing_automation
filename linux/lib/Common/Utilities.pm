package Common::Utilities;

use strict;
use warnings;
use Mail::Sendmail;
use Data::Dumper;

sub new{
    my ($self,%hash) = @_;
    my @audience = split(/,/,$hash{audience});
    my $to_string = "";
    my $user = `whoami`;
    my @to = ();
    chomp ($user);
    foreach my $audience (@audience){
        chomp ($audience);
        if ($audience =~ /\@.*\.com/){
            push @to,$audience;
        }else{
            my $to_string = $audience."\@synopsys.com";
            push @to,$to_string;
        }
    
    }
    $to_string = join(",",@to);
    print "TO STRING : $to_string\n";
    $hash{'to'} = $to_string;
    $hash{'from'} = $user."\@synopsys.com";
    return bless { %hash },$self;
    
}
sub mail_error{
    my $self = shift;
    my $subject = shift;
    my $status = shift;
    my $logfile = shift;
    my $mail_subject = "$status : Linux Build : ";
    $mail_subject .= $subject;
    my $to = $self->{to};
    my $from = $self->{from};
    
    my %mail = ( To        => "$to",
                 From      => "$from",
                 Subject   => "$mail_subject",
                 "Content-type" => "text/html",
                );
    print Dumper (\%mail);
    open (OUT,$logfile)||die("Couldn't open file : $logfile : $!\n");
    while (<OUT>){
        chomp ($_);
        $mail{Message} .= $_."<br>";
    }
    print "Mailing data\n";
    close(OUT);
  sendmail(%mail) or die $Mail::Sendmail::error
}

sub check_status{
    my $self = shift;
    my $cmd = shift;
    if ($? == 0 ){
        print LOG "[INFO] : Execution of $cmd : Passed\n";
    }else{
        print LOG "[ERROR] : Execution of $cmd : Failed\n";
        $self->mail_error("$cmd Failed");
        exit;
    }
}

sub get_time {
    my $self = shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    $year += 1900;
    $mday += 1;
    my $newyear = sprintf("%04d",$year);
    my $month = sprintf ("%02d",$mday);
    my $day = sprintf ("%02d",$wday);
    my $hr = sprintf ("%02d",$hour);
    $min = sprintf ("%02d",$min);
    $sec = sprintf ("%02d",$sec);
    my $string = $year."-".$month."-".$day.":".$hr.":".$min.":".$sec;
    return $string;
}

1;
