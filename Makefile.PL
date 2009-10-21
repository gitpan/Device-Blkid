use 5.006001;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

WriteMakefile(
    NAME                => 'Device::Blkid',
    AUTHOR              => 'Bastian Friedrich <bastian.friedrich@collax.com>',
    VERSION_FROM        => 'lib/Device/Blkid.pm',
    ABSTRACT_FROM       => 'lib/Device/Blkid.pm',
    PREREQ_PM           => {
        'Exporter'      => 0,
        'Test::More'    => 0,
        'Test::Builder' => 0,
    },

    NEEDS_LINKING       => 1,
    LIBS		=> ['-lblkid'],
    INC                 => '-I.',

    EXE_FILES           => [],
    dist => { COMPRESS => 'bzip2 -9f', SUFFIX => 'bz2' },
    clean => { FILES => 'Device-Blkid-*' },
);
