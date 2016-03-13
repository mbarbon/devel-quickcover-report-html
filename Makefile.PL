use 5.008009;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME            => 'Devel::QuickCover::Report::Html',
    ABSTRACT_FROM   => 'lib/Devel/QuickCover/Report/Html.pm',
    VERSION_FROM    => 'lib/Devel/QuickCover/Report/Html.pm',
    LICENSE         => 'mit',
    PREREQ_PM       => {
        'Devel::QuickCover'     => 0,
        'IO::Compress::Gzip'    => 0,
        'Text::MicroTemplate'   => 0,
        'File::ShareDir'        => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'       => '7.10',
        'File::ShareDir::Install'   => 0,
    },
    EXE_FILES   => ['bin/qc-html-report.pl'],
);

package MY;
use File::ShareDir::Install qw(postamble);
