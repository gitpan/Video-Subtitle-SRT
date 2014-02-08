package Video::Subtitle::SRT;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/srt_time_to_milliseconds milliseconds_to_srt_time
		make_subtitle/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use strict;
use warnings;
our $VERSION = '0.05';

use Carp;
use POSIX 'floor';
use Carp;

sub new {
    my ($class, $callback) = @_;
    bless { callback => $callback }, $class;
}

# Turn on/off debugging; return value is current debugging value.

sub debug
{
    my $self = shift;
    $self->{debug} = shift if @_;
    $self->{debug};
}

sub parse
{
    my ($self, $stuff) = @_;

    if (ref($stuff) && (UNIVERSAL::isa($stuff, 'IO::Handle') || ref($stuff) eq 'GLOB')) {
        $self->parse_fh($stuff);
    }
    else {
        open my $fh, "<", $stuff or croak "$stuff: $!";
        $self->parse_fh($fh);
	close $fh or die $!;
    }
}

# Read the SRT from file handle $fh.

sub parse_fh
{
    my ($self, $fh) = @_;

    binmode $fh, ":raw:crlf";
    local $/ = "\n\n";
    while (my $chunk = <$fh>) {
        my @chunk = split /\r?\n/, $chunk;
        if ($chunk[-1] eq "") {
            pop @chunk;
        }

        my $data = $self->parse_chunk(\@chunk, $chunk);
        if ($self->{callback}) {
            eval {
		$self->{callback}->($data)
	    };
            warn $@ if $@ && $self->{debug};
            return if $@;
        }
    }
}

sub parse_chunk
{
    my ($self, $chunk_ref, $chunk) = @_;

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

sub srt_time_to_milliseconds
{
    my ($time) = @_;
    if ($time !~ /^(\d\d):(\d\d):(\d\d)(?:,(\d*))?$/) {
        croak "Time '$time' does not match SRT format";
    }
    my $milliseconds = int ($4);
    $milliseconds += ($1 * 60 * 60 + $2 * 60 + $3) * 1000;
    return $milliseconds;
}

sub milliseconds_to_srt_time
{
    my ($milliseconds) = @_;

    my $seconds = floor ($milliseconds / 1000);
    my $minutes = floor ($seconds / 60);
    my $hours = floor ($minutes / 60);
    $milliseconds %= 1000;
    $seconds %= 60;
    $minutes %= 60;
    return sprintf "%02d:%02d:%02d,%03d",
        $hours, $minutes, $seconds, $milliseconds;
}

sub make_subtitle
{
    my ($data) = @_;
    my $output = "";
    for my $field (qw/number start_time end_time text/) {
	if (! $data->{$field}) {
	    croak "Missing $field";
	}
    }
    # Bug: should check that the output has all the fields here.
    $output .= $data->{number} . "\n";
    $output .= $data->{start_time} . " --> " . $data->{end_time} . "\n";
    $output .= $data->{text} . "\n";
    $output .= "\n";
    return $output;
}

sub add
{
    my ($object, $data) = @_;
    if (! defined $object->{number}) {
        $object->{number} = 0;
    }
    $object->{number}++;
    $data->{number} = $object->{number};
    $object->{subtitles} .= make_subtitle ($data);
}

sub write_file
{
    my ($object, $file_name) = @_;
    my $file;
    if ($file_name) {
        # Not finished.
        die;
    }
    else {
        $file = *STDOUT;
    }
    $object->{subtitles} =~ s/\n/\r\n/g;
    print $file $object->{subtitles};
}
 
# Set the verbosity of the output.

sub set_verbosity
{
    my ($object) = @_;
    $object->{verbosity} = 1;
}

1;

__END__

=for stopwords SRT SubRip callback .SRT

=head1 NAME

Video::Subtitle::SRT - manipulate SRT subtitle files

=head1 SYNOPSIS

  use Video::Subtitle::SRT;

  my $subtitle = Video::Subtitle::SRT->new (\&callback);
  $subtitle->parse ($fh);

  sub callback {
      my $data = shift;
      # $data->{number}
      # $data->{start_time}
      # $data->{end_time}
      # $data->{text}
  }

=head1 DESCRIPTION

Video::Subtitle::SRT is a callback based parser to parse SubRip
subtitle files (.SRT). See the script F<adjust-srt> in the
distribution for how to use this module to create subtitle delay
adjusting tools.

=head1 METHODS

=head2 new

    my $srt_wranger = Video::Subtitle::SRT->new (\& function);

The argument is the function to call back when parsing.

The callback function takes one argument, a hash reference. The hash
has the following fields:

=over

=item start_time

The start time of the subtitle, as a text string, in the SRT time
format. This may be converted into a time in milliseconds from the
start of the video using L</srt_time_to_milliseconds>.

=item end_time

The end time of the subtitle, as a text string, in the SRT time
format. This may be converted into a time in milliseconds from the
start of the video using L</srt_time_to_milliseconds>.

=item text

The text of the subtitle.

=item number

The number of the subtitle.

=back

It does not need to return any value. It can die on error to halt
parsing.

=head2 parse

Parse a file handle,

    open my $fh, "<", 'movie.srt' or die $!;
    $srt_wrangler->parse ($fh);    
    close $fh or die $!;

or a file

    $srt_wrangler->parse ('movie.srt');

Parse the subtitle file and call the callback specified in L</new>.

=head1 FUNCTIONS

=head2 srt_time_to_milliseconds

Convert an SRT time into a time in milliseconds.

=head2 milliseconds_to_srt_time

Convert a time in milliseconds into an SRT time.

=head2 make_subtitle

    my $srt = make_subtitle (\%data);

Given a subtitle containing the fields C<< {number => 1, text =>
'Words', start_time => srt_time, end_time => srt_time} >>, make it
into an SRT subtitle. The return value is the subtitle. If any of the
fields is missing, this emits a fatal error.

=head2 add

    $srt->add ($data);

Add the line to the subtitles.

=head2 write_file

    $srt->write_file ();

Write the file of subtitles to STDOUT.

=head1 EXPORTS

Video::Subtitle::SRT exports the following functions on request:
L</srt_time_to_milliseconds>, L</milliseconds_to_srt_time>, and
L</make_subtitle>. All the functions can be exported using the tag
<code>:all</code>:

    use Video::Subtitle::SRT ':all';

=head1 SEE ALSO

=over

=item L<http://en.wikipedia.org/wiki/SubRip> 

This explains the format.

=item L<http://www.opensubtitles.org/>

=back

=head1 AUTHOR

The module's creator is Tatsuhiko Miyagawa
E<lt>miyagawa@bulknews.netE<gt>. The module is currently maintained by
Ben Bullock <bkb@cpan.org>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

