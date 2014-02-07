use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Video/Subtitle/SRT.pm';
my $repo = 'https://github.com/benkasminbullock/Video-Subtitle-SRT';


WriteMakefile (
    NAME => 'Video::Subtitle::SRT',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    EXE_FILES => [
        'bin/adjust-srt',
    ],
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.006001',
    LICENSE => 'perl',
);

