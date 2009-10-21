#!/usr/bin/perl -w

use Test::More tests => 42;
use Data::Dumper;

use FindBin qw($Bin);

use POSIX ();

BEGIN { use_ok('Device::Blkid', ':funcs', ':consts'); }


sub hashrefToString {
	my ($h) = @_;

	my $k = keys(%{$h});
	my $ret = '';

	foreach my $k (keys(%{$h})) {
		$ret .= ', ' if ($ret);
		$ret .= sprintf('%s = %s', $k, $h->{$k});
	}
	return $ret;
}

#
# Device names, file names
#
my $checkdev = "/dev/sda1";

my $cachefile = '/etc/blkid.tab';
$cachefile = '/dev/blkid.tab' if (! -e $cachefile);
$cachefile = undef if (! -e $cachefile);

diag(sprintf('Using %s as cache', ($cachefile ? $cachefile : '(undef)')));

#
# Constants defined?
#

is(BLKID_DEV_FIND, 0, 'Constant BLKID_DEV_FIND set correctly');

#
# blkid_devno_to_devname
#
is (blkid_devno_to_devname(2049), $checkdev, 'Device 2049 is ' . $checkdev);
is (blkid_devno_to_devname(8, 1), $checkdev, 'Device 8, 1 is ' . $checkdev);
is (blkid_devno_to_devname(1), undef, 'Device 1 is undef');

#
# Cache object
#
my $cache;

$cache = blkid_get_cache();
isa_ok($cache, 'Device::Blkid::Cache', 'cache from empty file name (empty arg list) is a valid cache');

$cache = blkid_get_cache($cachefile);

isa_ok($cache, 'Device::Blkid::Cache', sprintf('cache from %s is a valid cache', ($cachefile ? $cachefile : '(undef)')));

ok(!defined(blkid_put_cache('Just a text')), "Bogus cache was correctly rejected");
ok(!defined(blkid_gc_cache('Just a text')), "Bogus cache was correctly rejected by blkid_gc_cache");

ok(blkid_gc_cache($cache), "Garbage collection on the cache");

ok(blkid_put_cache($cache), "Successfully put the cache again");
is($cache, undef, 'Cache is undef after put');


diag("Re-loading cache, get dev obj for $checkdev");
$cache = blkid_get_cache($cachefile);
my $dev = blkid_get_dev($cache, $checkdev, 0);

is(blkid_dev_devname($dev), $checkdev, "blkid_dev_devname returned '$checkdev' again");


##############################################
#
# Continue only if running on linux, and have an fstab
# blkid only expected to exist on linux, so that does not matter

die('Expecting to run under Linux -- Perl reports "' . $^O . '". Cannot cope with that -- exiting.') if ($^O ne 'linux');
die('Unable to find an fstab -- exiting.') if (! -e '/etc/fstab');

##############################################
#
# Evaluate mount table
#

my $rootdev;
my $roottype;
my $rootuuid;
my $swapdev;

my $rootobj;
my $swapobj;

my $mtab;

diag("Evaluating fstab");
open($mtab, '<', '/etc/fstab');
while (<$mtab>) {
	$_ =~ s/#.*//;
	my ($_dev, $_mpath, $_type, @_more) = split();
	next unless defined($_mpath);
	if ($_mpath eq '/') {
		if ($_dev =~ m#^/dev#) {
			$rootdev = $_dev;
			$roottype = $_type;
			diag("Found root dev $rootdev type $roottype");
		} else {
			diag("label-based root dev found. Cannot proceed.");
		}
	} elsif ($_type eq 'swap') {
		$swapdev = $_dev;
		diag("Found swap space $swapdev");
	}

}


die ("Tests require an existing swap entry and a correct root fs entry in fstab -- exiting.") if (!$rootdev || !$swapdev);

$rootuuid = blkid_get_tag_value($cache, 'UUID', $rootdev);

##############################################
#
# blkid_get_tag_value, blkid_get_devname
#

is(blkid_get_tag_value($cache, 'TYPE', $rootdev), $roottype, sprintf('Root device %s has type %s as expected', $rootdev, $roottype));
is(blkid_get_tag_value($cache, 'TYPE', $swapdev), 'swap', sprintf('Swap device %s has type %s as expected', $swapdev, 'swap'));
is(blkid_get_devname($cache, 'TYPE', 'swap'), $swapdev, 'blkid_get_devname returned swap device for type swap');



##############################################
#
# Iteration, searching
#

my $foundswap;
my $foundroot;
my $foundroot2;

foreach my $type ('swap', $roottype, '(undef)') {

	my $iter = blkid_dev_iterate_begin($cache);

	if ($type ne '(undef)') {
		my $ret = blkid_dev_set_search($iter, 'TYPE', $type);
		ok($ret == 0, sprintf('Successfully set search filter %s', ($type ? $type : '(undef)')));
	}

	while (my $d = blkid_dev_next($iter)) {
		my $dname = blkid_dev_devname($d);
		diag(sprintf('While searching for device with type %s, found dev %s with attributes %s', ($type ? $type : '(undef)'), $dname, hashrefToString($d->toHash)));
		if (($type eq 'swap') && ($dname eq $swapdev)) {
			$foundswap = 1;
			$swapobj = $d;
		}
		if (($type eq $roottype) && ($dname eq $rootdev)) {
			$foundroot = 1;
			$rootobj = $d;
		}
		if (($type eq '(undef)') && ($dname eq $rootdev)) {
			$foundroot2 = 1;
		}

	}

	blkid_dev_iterate_end($iter);
}

ok($foundswap, 'Found my swap again');
ok($foundroot, 'Found my root again');
ok($foundroot, 'Found my root in unrestricted search');

##############################################
#
# blkid_dev_has_tag
#

my $tags = $swapobj->toHash();	# toHash includes blkid_tag_iterate_begin, blkid_tag_next, blkid_tag_iterate_end
ok((defined($tags->{TYPE}) && defined($tags->{UUID})), 'tag iteration includes type and uuid for swap device');

ok(blkid_dev_has_tag($swapobj, 'TYPE', 'swap'), 'swap device is correctly labeled as swap');
ok(!blkid_dev_has_tag($swapobj, undef, 'ext3'), 'blkid_dev_has_tag returns false with undef type arg');
ok(!blkid_dev_has_tag($swapobj, 'LABEL', undef), 'blkid_dev_has_tag returns false with undef value arg and invalid type arg');



##############################################
#
# blkid_find_dev_with_tag
#

my $swapobj2 = blkid_find_dev_with_tag($cache, 'TYPE', 'swap');
is(blkid_dev_devname($swapobj2), $swapdev, "Found swap device $swapdev via blkid_find_dev_with_tag with values " . hashrefToString($swapobj2->toHash));


##############################################
#
# String parsing, encoding, lib version, similar
#

my $s = 'LABEL="foo"';
my $parsed = blkid_parse_tag_string($s);
is_deeply($parsed, { value => 'foo', type => 'LABEL' }, 'blkid_parse_tag_string parsed string "' . $s .'" successfully');

$parsed = blkid_parse_tag_string('LABEfoo"');
ok(!$parsed, 'blkid_parse_tag_string successfully rejected a broken string');

$parsed = blkid_parse_version_string('1.23.45');
is($parsed, '12345', 'blkid_parse_version_string parsed a version');

$s = "safe string with Umlauts äöü";
my $s2 = $s;
$s2 =~ s/\s/\\x20/g;
is(blkid_encode_string($s), $s2, 'blkid_encode_string transformed string "' . $s . '" to "' . $s2 . '"');
$s2 = $s;
$s2 =~ s/\s/_/g;
is(blkid_safe_string($s), $s2, 'blkid_safe_string transformed whitespace in ' . $s);

my $version = blkid_get_library_version();
my @version_keys = sort(keys(%{$version}));
is_deeply(\@version_keys, [ 'date', 'int', 'ver' ], 'blkid_get_library_version returns a date, an internal version, and a version');


##############################################
#
# blkid_evaluate_tag
#

SKIP: {
	skip 'No uuid for root device', 2 if (!$rootuuid);

	my $rootdev2 = blkid_evaluate_tag('UUID', $rootuuid, $cache);
	is($rootdev2, $rootdev, "blkid_evaluate_tag returned $rootdev for UUID=$rootuuid");
	$rootdev2 = blkid_evaluate_tag('UUID', $rootuuid);
	is($rootdev2, $rootdev, "blkid_evaluate_tag returned $rootdev for UUID=$rootuuid (using no-cache variant)");
}

##############################################
#
# known fs types
#

ok(blkid_known_fstype('ext3'), 'blkid knows fstype ext3');
ok(!blkid_known_fstype('nosuchfs'), 'blkid correctly does not know fstype nosuchfs');

##############################################
#
# probe_all(_new)
#

ok(blkid_probe_all($cache), 'blkid_probe_all called successfully');
ok(blkid_probe_all_new($cache), 'blkid_probe_all_new called successfully');

##############################################
#
# blkid_send_uevent
#

SKIP: {
	skip 'blkid_send_uevent will not work when called as non-root, skipping', 2 if ($> != 0);

	ok(blkid_send_uevent('/dev/sda1', 'unknownAction'), 'blkid_send_uevent sends action');
	ok(!blkid_send_uevent('nosuchdevice', 'invalidaction'), 'blkid_send_uevent correctly fails sending action to invalid device');
}


##############################################
#
# blkid_get_dev_size
#
my $fn = $Bin . '/imgs/ext2.img';
my $fd = POSIX::open($fn);
is(blkid_get_dev_size($fd), 1048576, "Test image $fn is 1M in size as expected");
POSIX::close($fd);


##############################################
#
# blkid_verify
#

$swapobj2 = blkid_verify($cache, $swapobj);
isa_ok($swapobj2, 'Device::Blkid::Device', 'blkid_verify returned a valid device object:');

