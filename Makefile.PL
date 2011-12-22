use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Video/Subtitle/SRT.pm';

WriteMakefile (
    NAME => 'Video::Subtitle::SRT',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'PerlIO::eol' => 0,
    },
    EXE_FILES => [
        'bin/adjust-srt',
    ],
);

