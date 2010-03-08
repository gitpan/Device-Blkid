# $Id: Blkid.pm,v 1.13 2010/03/08 12:57:59 bastian Exp $
# Copyright (c) 2007 Collax GmbH
package Device::Blkid;

=head1 NAME

Device::Blkid - Interface to libblkid

=head1 VERSION

Version 0.9

=cut

our $VERSION = "0.9.1";

=head1 SYNOPSIS

B<WARNING: This module requires libblkid 2.16 or newer, i.e. a version
that ships with util-linux-ng (in contrast to older library versions, which
were part of e2fsprogs).>

C<Device::Blkid> closely resembles the native interface of libblkid. All
functions provided by libblkid are available from Perl as well. Most
functions work exactly the same way, although a few have been slightly
modified to behave a little more "Perlish".

The most common way of using libblkid will be requesting a device (name)
referring to a device with a given attribute (e.g., "return device name
for LABEL=foo"), or you want all tags of a certain device.

In most cases, it is sensible to use the blkid cache; "undef" will work
in most cases.

 use Device::Blkid qw(:funcs);

 my $cache = blkid_get_cache();

 # Request (first) device with given attribute
 my $devname = blkid_get_devname($cache, 'LABEL', 'foo');
 print("Device $devname has label foo\n");

 # Request attributes of given device
 my $label = blkid_get_tag_value($cache, 'LABEL', '/dev/sda1');

 # Request all attributes of a given device
 use Data::Dumper;
 my $device = blkid_get_dev($cache, '/dev/sda1', 0);
 print("Dump of device attributes: " . Dumper($device));

Most devices contain a label, a UUID, and a type.

Please note that functions in section L</probe.c> are currently untested and
undocumented.

=head1 EXPORT

No functions or variables are exported per default. All functions and
constants listed below can be imported explicitly, though.

An export tag C<:funcs> exports all functionsprovided by this module;
C<:consts> exports all known constants.

=cut

use 5.006001;
use warnings;
use strict;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = (
	consts	=> [qw(
			BLKID_DEV_FIND
			BLKID_DEV_CREATE
			BLKID_DEV_VERIFY
			BLKID_DEV_NORMAL

			BLKID_PROBREQ_LABEL
			BLKID_PROBREQ_LABELRAW
			BLKID_PROBREQ_UUID
			BLKID_PROBREQ_UUIDRAW
			BLKID_PROBREQ_TYPE
			BLKID_PROBREQ_SECTYPE
			BLKID_PROBREQ_USAGE
			BLKID_PROBREQ_VERSION

			BLKID_USAGE_FILESYSTEM
			BLKID_USAGE_RAID
			BLKID_USAGE_CRYPTO
			BLKID_USAGE_OTHER

			BLKID_FLTR_NOTIN
			BLKID_FLTR_ONLYIN
		)],
	funcs	=> [qw(
			blkid_put_cache
			blkid_get_cache
			blkid_gc_cache
			blkid_devno_to_devname
			blkid_dev_devname
			blkid_probe_all
			blkid_probe_all_new
			blkid_get_dev
			blkid_get_dev_size
			blkid_verify
			blkid_get_tag_value
			blkid_get_devname
			blkid_dev_iterate_begin
			blkid_dev_set_search
			blkid_dev_next
			blkid_dev_iterate_end

			blkid_tag_iterate_begin
			blkid_tag_next
			blkid_tag_iterate_end

			blkid_dev_has_tag
			blkid_find_dev_with_tag
			blkid_parse_tag_string
			blkid_parse_version_string
			blkid_get_library_version
			blkid_encode_string
			blkid_safe_string
			blkid_send_uevent
			blkid_evaluate_tag
			blkid_known_fstype

			blkid_new_probe
			blkid_free_probe
			blkid_reset_probe

			blkid_probe_set_device
			blkid_probe_set_request
			blkid_probe_filter_usage
			blkid_probe_filter_types

			blkid_probe_invert_filter
			blkid_probe_reset_filter
			blkid_do_probe
			blkid_do_safeprobe
			blkid_probe_numof_values
			blkid_probe_get_value
			blkid_probe_lookup_value
			blkid_probe_has_value
		)],
);
Exporter::export_ok_tags('consts');
Exporter::export_ok_tags('funcs');

=head1 CONSTANTS

This module provides a number of constants that are also contained in the
blkid.h header:

=over

=item

BLKID_DEV_

=over

=item

BLKID_DEV_FIND

=item

BLKID_DEV_CREATE

=item 

BLKID_DEV_VERIFY

=item

BLKID_DEV_NORMAL

=back

=item

BLKID_PROBREQ_

=over

=item

BLKID_PROBREQ_LABEL

=item

BLKID_PROBREQ_LABELRAW

=item

BLKID_PROBREQ_UUID

=item

BLKID_PROBREQ_UUIDRAW

=item

BLKID_PROBREQ_TYPE

=item

BLKID_PROBREQ_SECTYPE

=item

BLKID_PROBREQ_USAGE

=item

BLKID_PROBREQ_VERSION

=back

=item

BLKID_USAGE_

=over

=item

BLKID_USAGE_FILESYSTEM

=item

BLKID_USAGE_RAID

=item

BLKID_USAGE_CRYPTO

=item

BLKID_USAGE_OTHER

=back

=item

BLKID_FLTR_

=over

=item

BLKID_FLTR_NOTIN

=item

BLKID_FLTR_ONLYIN

=back

=back

You may either access these constants in a fully qualified way
(e.g., C<Device::Blkid::BLKID_DEV_FIND>), by importing single constants,
or by importing the C<:consts> token. See L</EXPORT> section.

=cut

use constant BLKID_DEV_FIND	=> 0x0000;
use constant BLKID_DEV_CREATE	=> 0x0001;
use constant BLKID_DEV_VERIFY	=> 0x0002;
use constant BLKID_DEV_NORMAL	=> (BLKID_DEV_CREATE | BLKID_DEV_VERIFY);

use constant BLKID_PROBREQ_LABEL	=> (1 << 1);
use constant BLKID_PROBREQ_LABELRAW	=> (1 << 2);
use constant BLKID_PROBREQ_UUID		=> (1 << 3);
use constant BLKID_PROBREQ_UUIDRAW	=> (1 << 4);
use constant BLKID_PROBREQ_TYPE		=> (1 << 5);
use constant BLKID_PROBREQ_SECTYPE	=> (1 << 6);
use constant BLKID_PROBREQ_USAGE	=> (1 << 7);
use constant BLKID_PROBREQ_VERSION	=> (1 << 8);

use constant BLKID_USAGE_FILESYSTEM	=> (1 << 1);
use constant BLKID_USAGE_RAID		=> (1 << 2);
use constant BLKID_USAGE_CRYPTO		=> (1 << 3);
use constant BLKID_USAGE_OTHER		=> (1 << 4);

use constant BLKID_FLTR_NOTIN		=> 1;
use constant BLKID_FLTR_ONLYIN		=> 2;


=head1 FUNCTIONS

The original libblkid functions are not split into categories; they are,
however, listed per source file. This sequence is resembled here.

=head2 cache.c

=head3 Function C<blkid_put_cache($cache)>

Writes the cache object referenced by C<$cache> back to disk. C<$cache> is
invalidated by this call and B<MUST NOT> be used afterwards.

Returns a true value on success, undef on failure.

=head3 Function C<blkid_get_cache($filename)>

Reads the cache from given file, or from the default cache file if $filename
is not defined.

Returns a C<Device::Blkid::Cache> object (which is only usable as argument
to other functions) on success, undef on failure.

=head3 Function C<blkid_gc_cache($cache)>

Runs a garbage collection on given cache object.

Returns a true value on success, undef on failure (cache invalid).


=head2 dev.c

The following functions provide iterations over multiple devices: either all,
or a subset filtered by a search. Get an iterator with
L</blkid_dev_iterate_begin>, optionally set a search filter with
L</blkid_dev_set_search>, fetch the next object with
L</blkid_dev_next>, and finally destroy the iterator with
L</blkid_dev_iterate_end>.

While you are encouraged to call L</blkid_dev_iterate_end>, the class
C<Device::Blkid::DevIterate> will automaticall destroy the associated
iterator when it is removed from memory (i.e., when it is no longer
referenced).

=head3 Function C<blkid_dev_devname($dev)>

Returns the device name associated with a C<Device::Blkid::Device> object,
or undef uppon failure.

=head3 Function C<blkid_dev_iterate_begin($cache)>

Returns an iterator of type C<Device::Blkid::DevIterate> to iterate over
multiple devices (or undef uppon failure).

A cache object is mandatory for this function.

=head3 Function C<blkid_dev_set_search($iter, $search_type, $search_value)>

Restricts objects returned by iterators to given search; e.g., filter for
ext3 file systems with this:

 blkid_dev_set_search($iter, 'TYPE', 'ext3');

=head3 Function C<blkid_dev_next($iterate)>

Returns the next device (as a C<Device::Blkid::Device> object) in this
iteration, or undef, when the end of the list is reached (or another
problem was encountered).

=head3 Function C<blkid_dev_iterate_end($iterate)>

Returns the $iterate object. Does not need to be called (auto-destroyed by
perl).

=head2 devno.c

=head3 Function C<blkid_devno_to_devname(major, minor|devno)>

Returns a device name for any given device number. If passed two arguments, the
device number (devno) will be C<major << 8 + minor>.

 printf("Device 8, 1 is %s, device 2049 is %s as well\n",
 	blkid_devno_to_devname(8,1),
	blkid_devno_to_devname(2049));

Undef is returned for non-existing devices:

 if (!blkid_devno_to_devname(0, 1)) {
 	print("No Device 0, 1 found\n");
 }

=head2 devname.c

=head3 Function C<blkid_probe_all($cache)>

Probes all devices in cache. Returns a true value on success, false on failure.

=head3 Function C<blkid_probe_all_new($cache)>

Probes new devices to cache. Returns a true value on success, false on failure.

=head3 Function C<blkid_get_dev($cache, $devname, $flags)>

Returns a C<Device::Blkid::Device> object referring the given device name (or
undef uppon failure).

Flag BLKID_DEV_CREATE may be given in the flags argument to generate a new
cache entry.

=head2 getsize.c

=head3 Function C<blkid_get_dev_size($fd)>

Returns the size of the given device. Please note that the device is passed by
a file descriptor (B<not a Perl file handle!>). See L<POSIX::open> for more
information.


=head2 verify.c

=head3 Function C<blkid_verify($cache, $dev)>

Verify that the data in C<$dev> is consistent with what is on the actual
block device (using the devname field only). Normally this will be
called when finding items in the cache, but for long running processes
is also desirable to revalidate an item before use.

C<$dev> is expected to be a C<Device::Blkid::Device> object (as returned e.g.
by blkid_get_dev), not a device name.

=head2 read.c

C<read.c> does not contain any user-accessible functions.

=head2 resolve.c

=head3 Function C<blkid_get_tag_value($cache, $tagname, $devname)>

Returns the requested tag for a device (or false uppon failure), e.g.:

 printf("Type of my sda1 is %s\n",
 	blkid_get_tag_value($cache, 'TYPE', '/dev/sda1'));

=head3 Function C<blkid_get_devname($cache, $token, $value)>

Return the first device with the given tag/value pair, e.g.

 printf("Device with label foo is %s\n",
 	blkid_get_devname($cache, 'LABEL', 'foo'));
 printf("Identical request with token as name=value: %s\n",
 	blkid_get_devname($cache, 'LABEL=foo'));

=head2 tag.c

The three following functions
C<blkid_tag_iterate_begin($dev)>,
C<blkid_tag_next($iterate)>, and
C<blkid_tag_iterate_end> iterate over the attributes of a requested
device (C<Device::Blkid::Device>, not device name).

Object method L<Device::Blkid::Device::toHash()> provides a much simpler
way to access all attributes.

=head3 Function C<blkid_tag_iterate_begin($dev)>

Fetches an iterator object for the given device.

=head3 Function C<blkid_tag_next($iterate)>

Returns the next attribute set for the device as a hash of this structure:

 $VAR1 = {
 	type	=> 'LABEL',
	value	=> 'myLabel',
 };

Returns undef, when there are no more entries (or uppon other failures).

=head3 Function C<blkid_tag_iterate_end($iterate)>

Frees data associated with this object. Auto-destruction is implemented, when
the iterator object is freed, i.e. you do not have to call this function
manually.

=head3 Function C<blkid_dev_has_tag($dev, $type, $value)>

Checks whether the given device has the attribute $type=$value set; returns
true in that case, false otherwise.

 if (blkid_dev_has_tag($dev, 'LABEL', 'foo')) {
 	print("Yes, your device is labeled foo\n");
 }

=head3 Function C<blkid_find_dev_with_tag($cache, $type, $value)>

Finds (and returns) the first device with the given type/value pair,
and returns it as an object of type C<Device::Blkid::Device>.

=head3 Function C<blkid_parse_tag_string($token)>

For a given string "foo=bar", returns a hash
C<{ type => 'foo', value => 'bar'}>.

Returns undef if the string is not parsable.

=head2 version.c

=head3 Function C<blkid_parse_version_string($ver_string)>

Returns an integer representation of a version string. Internal format
in libblkid.

=head3 Function C<blkid_get_library_version($ver_string, $date_string)>

Returns a hash containing basic information about the installed version of
libblkid:

 $VAR1 = {
 	int	=> 2160,
	ver	=> '2.16.0',
	date	=> '10-Feb-2009',
 };

=head2 encode.c

=head3 Function C<blkid_encode_string($str)>

Encode all potentially unsafe characters of a string to the corresponding
hex value prefixed by '\x'.

Returns that string on success, or undef on failure. Other than the libblkid
version, no partial strings are returned.

=head3 Function C<blkid_safe_string($str)>

Allows plain ascii, hex-escaping and valid utf8. Replaces all whitespaces
with '_'.

Returns that string on success, or undef on failure.

=head2 evaluate.c

=head3 Function C<blkid_send_uevent($devname, $action)>

Sends the given action as a uevent to the udev entry of the respective device.

Returns a true value on success, a false value on failure. Please note that
"success" does B<not> necessarily mean that the uevent was triggered
successfully.

=head3 Function C<blkid_evaluate_tag($token, $value, $cache)>

Returns the device name where the given token=value pair holds, or undef on
failure.

C<$cache> argument may be ommited.

=head2 probe.c

Most functions in this section have NOT been tested well and currently remain
undocumented. Please see libblkid for further information.

=head3 Function C<blkid_known_fstype($fstype)>

Checks whether fs type C<$fstype> is known by the installed version of
libblkid. Returns true in that case, false otherwise.

=head3 Function C<blkid_new_probe()>

Undocumented (and largely untested).

=head3 Function C<blkid_free_probe($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_reset_probe($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_set_device($pr, $fd, $off, $size)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_set_request($pr, $flags)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_filter_usage($pr, $flag, $usage)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_filter_types($pr, $flag, $names, ...)>

Undocumented (and largely untested).

B<DO NOT USE.>

=head3 Function C<blkid_probe_invert_filter($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_reset_filter($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_do_probe($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_do_safeprobe($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_numof_values($pr)>

Undocumented (and largely untested).

=head3 Function C<blkid_probe_get_value($pr, $num)>

Undocumented (and largely untested).

Returns a string on success, undef on failure (this differs from the library
behavior).

=head3 Function C<blkid_probe_lookup_value($pr, $name)>

Undocumented (and largely untested).

Returns a string on success, undef on failure (this differs from the library
behavior).

=head3 Function C<blkid_probe_has_value($pr, $name)>

Undocumented (and largely untested).

=cut

bootstrap Device::Blkid;

package Device::Blkid::Device;

=head1 Package C<Device::Blkid::Device>

Objects of this type are returned by a number of functions in the
C<Device::Blkid> package. They cannot be user-created and are
(almost) only expected to be passed to other functions of C<Device::Blkid>.

A single object method exists:

=head2 METHODS

=head3 Method C<toHash()>

Returns the tags of this device as a hash, e.g.

 $VAR1 = {
 	'TYPE'	=> 'swap',
	'UUID'	=> '12345678-1234-1234-1234-123457890123',
 };

This method uses L<Device::Blkid::blkid_tag_iterate_begin>,
L<Device::Blkid::blkid_tag_next>, and
L<Device::Blkid::blkid_tag_iterate_end> to iterate over the device tags;
you might as well call these functions yourself.

=cut

sub toHash {
	my ($self) = @_;

	my $ret = {};

	my $iter = Device::Blkid::blkid_tag_iterate_begin($self);
	return undef if (!$iter);

	while (my $h = Device::Blkid::blkid_tag_next($iter)) {
		$ret->{$h->{type}} = $h->{value};
	}

	Device::Blkid::blkid_tag_iterate_end($iter);

	return $ret;
}

package Device::Blkid::DevIterate;

sub DESTROY {
	my ($self) = @_;
	Device::Blkid::_DO_blkid_dev_iterate_end($self);
}

package Device::Blkid::TagIterate;

sub DESTROY {
	my ($self) = @_;
	Device::Blkid::_DO_blkid_tag_iterate_end($self);
}

1;

=head1 AUTHOR

Bastian Friedrich, C<< <bastian.friedrich at collax.com> >>

=head1 BUGS

Device::Blkid 0.9 is expected to contain a number of memory leaks.

Please report any bugs or feature requests to C<bug-device-blkid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Blkid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Blkid


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Blkid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Blkid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Blkid>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Blkid/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Bastian Friedrich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
