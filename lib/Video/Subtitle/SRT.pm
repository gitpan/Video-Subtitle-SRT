package Video::Subtitle::SRT;

use strict;
our $VERSION = '0.01';

use Carp;
use PerlIO::eol;

sub new {
    my($class, $callback) = @_;
    bless { callback => $callback }, $class;
}

sub debug {
    my $self = shift;
    $self->{debug} = shift if @_;
    $self->{debug};
}

sub parse {
    my($self, $stuff) = @_;

    if (ref($stuff) && (UNIVERSAL::isa($stuff, 'IO::Handle') || ref($stuff) eq 'GLOB')) {
        $self->parse_fh($stuff);
    } else {
        open my $fh, "<", $stuff or croak "$stuff: $!";
        $self->parse_fh($fh);
    }
}

sub parse_fh {
    my($self, $fh) = @_;

    binmode $fh, ":raw:eol(LF)";
    local $/ = "\n\n";
    while (my $chunk = <$fh>) {
        my @chunk = split /\r?\n/, $chunk;
        if ($chunk[-1] eq "") {
            pop @chunk;
        }

        my $data = $self->parse_chunk(\@chunk, $chunk);
        if ($self->{callback}) {
            eval { $self->{callback}->($data) };
            warn $@ if $@ && $self->{debug};
            return if $@;
        }
    }
}

sub parse_chunk {
    my($self, $chunk_ref, $chunk) = @_;

    if (@$chunk_ref < 3) {
        croak "Odd number of lines: \n$chunk";
    }

    my $data;
    if ($chunk_ref->[0] !~ /^\d+$/) {
        croak "Number must be digits: '$chunk_ref->[0]'";
    }
    $data->{number} = $chunk_ref->[0];

    my $time_re = '(\d{2}:\d{2}:\d{2}(?:,\d*)?)';
    unless ($chunk_ref->[1] =~ /^$time_re --> $time_re$/) {
        croak "Invalid time range: $chunk_ref->[1]";
    }
    $data->{start_time} = $1;
    $data->{end_time}   = $2;

    $data->{text} = join "\n", @{$chunk_ref}[2..$#$chunk_ref];

    return $data;
}

1;
__END__

=for stopwords SRT SubRip callback .SRT

=head1 NAME

Video::Subtitle::SRT - Handle Subtitle (.SRT) file with a callback

=head1 SYNOPSIS

  use Video::Subtitle::SRT;

  my $subtitle = Video::Subtitle::SRT->new(\&callback);
  $subtitle->parse($fh);

  sub callback {
      my $data = shift;
      # $data->{number}
      # $data->{start_time}
      # $data->{end_time}
      # $data->{text}
  }

=head1 DESCRIPTION

Video::Subtitle::SRT is a callback based parser to parse SubRip
subtitle files (.SRT). See L<bin/adjust-srt> how to use this module to
create subtitle delays adjusting tools.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/SubRip> L<http://www.opensubtitles.org/>

=cut
