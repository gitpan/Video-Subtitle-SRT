use inc::Module::Install;
name 'Video-Subtitle-SRT';
all_from 'lib/Video/Subtitle/SRT.pm';

build_requires 'Test::More';
requires 'PerlIO::eol';
install_script 'bin/adjust-srt';

use_test_base;
auto_include;
WriteAll;
