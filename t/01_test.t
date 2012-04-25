use Test::More tests => 3;
use Video::Subtitle::SRT 'make_subtitle';
use FindBin;

my @files = (qw/sample sample-crlf/);

#plan tests => scalar @files;

my $start = '00:00:20,000';
my $end = '00:00:24,400';

for my $file (@files) {
    my $file_name = "$FindBin::Bin/$file.srt";
    my $callback = sub {
        my $data = shift;
        is_deeply $data, {
            number => 1,
            start_time => $start,
            end_time => $end,
            text => "In connection with a dramatic increase\nin crime in certain neighbourhoods,",
        };
        die;
    };

    my $st = Video::Subtitle::SRT->new ($callback);
    $st->parse ($file_name);
}

my $subtitle = make_subtitle ({
    start_time => $start,
    end_time => $end,
    text => 'TM',
});
#print "$subtitle\n";
like ($subtitle, qr/\Q$start\E --> \Q$end\E/, "Test output of subtitles");
