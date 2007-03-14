use Test::More;
use Video::Subtitle::SRT;

my @files = ("t/sample.srt", "t/sample-crlf.srt");

plan tests => scalar @files;

for my $file (@files) {

    my $callback = sub {
        my $data = shift;
        is_deeply $data, {
            number => 1,
            start_time => "00:00:20,000",
            end_time => "00:00:24,400",
            text => "In connection with a dramatic increase\nin crime in certain neighbourhoods,",
        };
        die;
    };

    my $st = Video::Subtitle::SRT->new($callback);
    $st->parse($file);
}
