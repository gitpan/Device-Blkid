use 5.008001;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

use lib 'inc/';
use Devel::CheckLib;
check_lib_or_exit(
	function	=> '
		const char *v;
		const char *d;
		int i;
		blkid_get_library_version(&v, &d);
		i = blkid_parse_version_string(v);
		if (i < 2160) {
			printf("Version mismatch for libblkid, or invalid library -- blkid_parse_version_string returned %d\n", i);
			return(1);
		}
		return 0;',
	lib		=> 'blkid',
	header		=> 'blkid/blkid.h',
);

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
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Device-Blkid-*' },
);
