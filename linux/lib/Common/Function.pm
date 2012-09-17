package Common::Function;

sub new{
    my $self = shift;
    my $fh = shift;
    $self->_update_file($fh);
    print "FH : $fh\n";
    return bless {};
}

sub _update_file{
    my ($self,$fh)=@_;
    print "Function called : $fh\n";
    print $fh "Hai line from module\n";
}

1
