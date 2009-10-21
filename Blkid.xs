/*
 * $Id: Blkid.xs,v 1.21 2009/10/21 20:59:06 bastian Exp $
 *
 * Copyright (C) 2009 Collax GmbH
 *                    (Bastian Friedrich <bastian.friedrich@collax.com>)
 */

#include <unistd.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <blkid/blkid.h>

/*
 * Bad code
 * TODO
 * _one_ function that does the same job...
 */
blkid_cache sv2cache(SV *sv, char *func) {
	blkid_cache cache = NULL;
	char err[256] = "Cache error";
	if (SvROK(sv)) {
		if (sv_derived_from(sv, "Device::Blkid::Cache")) {
			sv = SvRV(sv);
			if (SvIOK(sv)) {
				cache = INT2PTR(blkid_cache, SvIV(sv));
			} else {
				snprintf(err, sizeof(err)-1, "%s: Invalid argument (internal error)", func);
			}
		} else {
			snprintf(err, sizeof(err)-1, "%s: Invalid argument (not a Device::Blkid::Cache object)", func);
		}
	} else if (!SvOK(sv)) {
		/* "undef" -> return NULL */
		return NULL;
	} else {
		snprintf(err, sizeof(err)-1, "%s: Invalid argument (not an object)", func);
	}
	if (!cache)
		warn(err);

	return cache; /* In case of error above... */
}


blkid_dev sv2dev(SV *sv, char *func) {
	blkid_dev dev= NULL;
	char err[256] = "Device error";
	if (SvROK(sv)) {
		if (sv_derived_from(sv, "Device::Blkid::Device")) {
			sv = SvRV(sv);
			if (SvIOK(sv)) {
				dev = INT2PTR(blkid_dev, SvIV(sv));
			} else {
				snprintf(err, sizeof(err)-1, "%s: Invalid argument (internal error)", func);
			}
		} else {
			snprintf(err, sizeof(err)-1, "%s: Invalid argument (not a Device::Blkid::Device object)", func);
		}
	} else {
		snprintf(err, sizeof(err)-1, "%s: Invalid argument (not an object)", func);
	}
	if (!dev)
		warn(err);

	return dev; /* In case of error above... */
}


blkid_probe sv2probe(SV *sv, char *func) {
	blkid_probe probe = NULL;
	char err[256] = "Probe error";
	if (SvROK(sv)) {
		if (sv_derived_from(sv, "Device::Blkid::Probe")) {
			sv = SvRV(sv);
			if (SvIOK(sv)) {
				probe = INT2PTR(blkid_probe, SvIV(sv));
			} else {
				snprintf(err, sizeof(err)-1, "%s: Invalid argument (internal error)", func);
			}
		} else {
			snprintf(err, sizeof(err)-1, "%s: Invalid argument (not a Device::Blkid::Probe object)", func);
		}
	} else {
		snprintf(err, sizeof(err)-1, "%s: Invalid argument (not an object)", func);
	}
	if (!probe)
		warn(err);

	return probe; /* In case of error above... */
}


blkid_dev_iterate sv2dev_iterate(SV *sv, char *func) {
	blkid_dev_iterate dev_iterate = NULL;
	char err[256] = "dev_iterate error";
	if (SvROK(sv)) {
		if (sv_derived_from(sv, "Device::Blkid::DevIterate")) {
			sv = SvRV(sv);
			if (SvIOK(sv)) {
				dev_iterate = INT2PTR(blkid_dev_iterate, SvIV(sv));
			} else {
				snprintf(err, sizeof(err)-1, "%s: Invalid argument (internal error)", func);
			}
		} else {
			snprintf(err, sizeof(err)-1, "%s: Invalid argument (not a Device::Blkid::DevIterate object)", func);
		}
	} else {
		snprintf(err, sizeof(err)-1, "%s: Invalid argument (not an object)", func);
	}
	if (!dev_iterate)
		warn(err);

	return dev_iterate; /* In case of error above... */
}

blkid_tag_iterate sv2tag_iterate(SV *sv, char *func) {
	blkid_tag_iterate tag_iterate = NULL;
	char err[256] = "tag_iterate error";
	if (SvROK(sv)) {
		if (sv_derived_from(sv, "Device::Blkid::TagIterate")) {
			sv = SvRV(sv);
			if (SvIOK(sv)) {
				tag_iterate = INT2PTR(blkid_tag_iterate, SvIV(sv));
			} else {
				snprintf(err, sizeof(err)-1, "%s: Invalid argument (internal error)", func);
			}
		} else {
			snprintf(err, sizeof(err)-1, "%s: Invalid argument (not a Device::Blkid::TagIterate object)", func);
		}
	} else {
		snprintf(err, sizeof(err)-1, "%s: Invalid argument (not an object)", func);
	}
	if (!tag_iterate)
		warn(err);

	return tag_iterate; /* In case of error above... */
}


MODULE = Device::Blkid PACKAGE = Device::Blkid

PROTOTYPES: DISABLE

### typedef struct blkid_struct_dev *blkid_dev;
### typedef struct blkid_struct_cache *blkid_cache;
### typedef struct blkid_struct_probe *blkid_probe;
### 
### typedef int64_t blkid_loff_t;
### 
### typedef struct blkid_struct_tag_iterate *blkid_tag_iterate;
### typedef struct blkid_struct_dev_iterate *blkid_dev_iterate;
### 
### 
### 
### /* cache.c */
### extern void blkid_put_cache(blkid_cache cache);

# //  TODO: Segfaults XXX TODO XXX
# // Subsequent calls segfault (not the call to put_cache itself)
SV *
blkid_put_cache(_cache)
	SV *_cache
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_put_cache");
	PPCODE:
		if (cache) {
			blkid_put_cache(cache);
			sv_setsv(_cache, &PL_sv_undef);
			XPUSHs(sv_2mortal(newSViv(1)));
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern int blkid_get_cache(blkid_cache *cache, const char *filename);

SV *
blkid_get_cache( ... )
	PREINIT:
		blkid_cache cache;
		SV *_cache;
		int ret;
		char *filename;
		SV *_filename;
	PPCODE:
		filename = NULL;
		_filename = NULL;;
		/* items == null -> use default cache file name; use filename = NULL */
		if (items == 1) {
			_filename = ST(0);
			if (SvPOK(_filename)) {
				filename = SvPV_nolen(_filename);
				if (strcmp(filename, "") == 0) {	// Empty string
					filename = NULL;
				}
			}
		} else if (items > 1) {
			Perl_croak(aTHX_ "Usage: Device::Blkid::blkid_get_cache($filename)");
		}

		if ((ret = blkid_get_cache(&cache, filename)) != 0) {
			warn("error creating cache (%d)\n", ret);
			XPUSHs(&PL_sv_undef);
		} else {
			_cache = sv_newmortal();
			sv_setref_pv(_cache, "Device::Blkid::Cache", (void *)cache);
			SvREADONLY_on(SvRV(_cache));
			XPUSHs(_cache);
		}



### extern void blkid_gc_cache(blkid_cache _cache);

SV *
blkid_gc_cache(_cache)
	SV *_cache
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_gc_cache");
	PPCODE:
		if (cache) {
			blkid_gc_cache(cache);
			XPUSHs(sv_2mortal(newSViv(1)));
		} else {
			XPUSHs(&PL_sv_undef);
		}

### /* dev.c */
### extern const char *blkid_dev_devname(blkid_dev dev);
SV *
blkid_dev_devname(_dev)
	SV *_dev
	PREINIT:
		blkid_dev dev = sv2dev(_dev, "blkid_dev_devname");
		const char *ret;
	PPCODE:
		if (!dev) {
			XPUSHs(&PL_sv_undef);
		} else if (ret = blkid_dev_devname(dev)) {
			XPUSHs(sv_2mortal(newSVpv(ret, 0)));
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern blkid_dev_iterate blkid_dev_iterate_begin(blkid_cache cache);

SV *
blkid_dev_iterate_begin(_cache)
	SV *_cache
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_dev_iterate_begin");
		blkid_dev_iterate dev_iter = NULL;
		SV *_dev_iter;
	PPCODE:
		if (cache) {
			dev_iter = blkid_dev_iterate_begin(cache);
		}

		if (dev_iter) {
			_dev_iter = sv_newmortal();
			sv_setref_pv(_dev_iter, "Device::Blkid::DevIterate", (void *)dev_iter);
			SvREADONLY_on(SvRV(_dev_iter));
			XPUSHs(_dev_iter);
		} else {
			XPUSHs(&PL_sv_undef);
		}



### extern int blkid_dev_set_search(blkid_dev_iterate iter,
### 				char *search_type, char *search_value);

int
blkid_dev_set_search(_iter, search_type, search_value)
	SV *_iter
	char *search_type
	char *search_value
	INIT:
		blkid_dev_iterate iter = sv2dev_iterate(_iter, "blkid_dev_set_search");
		int ret;
	CODE:
		if (!(iter && search_type && search_value)) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_dev_set_search(iter, search_type, search_value);
	OUTPUT:
		RETVAL



### extern int blkid_dev_next(blkid_dev_iterate iterate, blkid_dev *dev);

SV *
blkid_dev_next(_iterate)
	SV *_iterate
	INIT:
		blkid_dev_iterate iterate = sv2dev_iterate(_iterate, "blkid_dev_next");
		blkid_dev dev;
		SV *_dev;
		int ret;
	PPCODE:
		if (!iterate) {
			XSRETURN_UNDEF;
		}

		ret = blkid_dev_next(iterate, &dev);
		if (ret != 0) {
			XSRETURN_UNDEF;
		}

		_dev = sv_newmortal();
		sv_setref_pv(_dev, "Device::Blkid::Device", (void *)dev);
		SvREADONLY_on(SvRV(_dev));
		XPUSHs(_dev);




### extern void blkid_dev_iterate_end(blkid_dev_iterate iterate);
# Object destructor calls _DO_... function below

void
blkid_dev_iterate_end(_iterate)
	SV *_iterate
	INIT:
		blkid_dev_iterate iterate = sv2dev_iterate(_iterate, "blkid_dev_iterate_end");
	CODE:
		if (iterate) {
			sv_setsv(_iterate, &PL_sv_undef);
		}

void
_DO_blkid_dev_iterate_end(_iterate)
	SV *_iterate
	INIT:
		blkid_dev_iterate iterate = sv2dev_iterate(_iterate, "blkid_dev_iterate_end");
	CODE:
		if (iterate) {
			blkid_dev_iterate_end(iterate);
		}

#
# blkid_devno_to_devname(devno)
#
# Returns devicename of device number major*256+minor
# Perl wrapper for correct argument types
#

SV *
blkid_devno_to_devname(major, ...)
	dev_t major
	PREINIT:
		char *ret;
		SV *arg2;
		dev_t devno;
	PPCODE:

		if (items > 2) {
			Perl_croak(aTHX_ "Usage: Device::Blkid::_blkid_devno_to_devname(major, minor|devno)");
		}

		devno = major;
		if (items == 2) {
			arg2 = ST(1);
			if (SvOK(arg2) && SvIOK(arg2)) {
				devno = (major << 8) + SvIV(arg2);
			} else {
				Perl_croak(aTHX_ "Usage: Device::Blkid::_blkid_devno_to_devname(major, minor|devno)");
			}
		}

		ret = blkid_devno_to_devname(devno);
		if (ret) {
			XPUSHs(sv_2mortal(newSVpv(ret, 0)));
		} else {
			XPUSHs(&PL_sv_undef);
		}


### /* devname.c */
### extern int blkid_probe_all(blkid_cache cache);

SV *
blkid_probe_all(_cache)
	SV *_cache
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_probe_all");
		int ret;
	PPCODE:
		if (cache) {
			ret = blkid_probe_all(cache);
			/* Reverse logic -- ret val. 0 is good! */
			if (ret == 0) {
				XPUSHs(sv_2mortal(newSViv(1)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}

### extern int blkid_probe_all_new(blkid_cache cache);

SV *
blkid_probe_all_new(_cache)
	SV *_cache
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_probe_all_new");
		int ret;
	PPCODE:
		if (cache) {
			ret = blkid_probe_all_new(cache);
			/* Reverse logic -- ret val. 0 is good! */
			if (ret == 0) {
				XPUSHs(sv_2mortal(newSViv(1)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}



### extern blkid_dev blkid_get_dev(blkid_cache cache, const char *devname,
### 			       int flags);


SV *
blkid_get_dev(_cache, _devname, flags)
	SV *_cache
	SV *_devname
	IV flags
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_probe_all_new");
		char *devname = NULL;
		blkid_dev dev = NULL;
		SV *_dev;
	PPCODE:
		if (!SvOK(_devname)) {
			warn("blkid_get_dev: invalid devname argument");
		} else {
			if (!SvPOK(_devname)) {
				warn("blkid_get_dev: invalid devname argument");
			} else {
				devname = SvPV_nolen(_devname);
			}
		}

		if (devname) {
			dev = blkid_get_dev(cache, devname, flags);
		}

		if (dev) {
			_dev = sv_newmortal();
			sv_setref_pv(_dev, "Device::Blkid::Device", (void *)dev);
			SvREADONLY_on(SvRV(_dev));
			XPUSHs(_dev);
		} else {
			XPUSHs(&PL_sv_undef);
		}



### /* getsize.c */
### extern blkid_loff_t blkid_get_dev_size(int fd);

IV
blkid_get_dev_size(fd)
	IV fd

### /* verify.c */
### extern blkid_dev blkid_verify(blkid_cache cache, blkid_dev dev);

SV *
blkid_verify(_cache, _dev)
	SV *_cache
	SV *_dev
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_verify");
		blkid_dev dev = sv2dev(_dev, "blkid_verify");
		blkid_dev ret;
		SV *_ret;
	PPCODE:
		if (cache && dev) {
			ret = blkid_verify(cache, dev);

			_ret = sv_newmortal();
			sv_setref_pv(_ret, "Device::Blkid::Device", (void *)ret);
			SvREADONLY_on(SvRV(_ret));
			XPUSHs(_ret);
		} else {
			XPUSHs(&PL_sv_undef);
		}
		

### /* read.c */
### 
### /* resolve.c */
### extern char *blkid_get_tag_value(blkid_cache cache, const char *tagname,
### 				       const char *devname);

char *
blkid_get_tag_value(_cache, _tagname, _devname)
	SV *_cache
	SV *_tagname
	SV *_devname
	PREINIT:
		blkid_cache cache = sv2cache(_cache, "blkid_get_tag_value");
		char *tagname = SvOK(_tagname) ? SvPV_nolen(_tagname) : NULL;
		char *devname = SvOK(_devname) ? SvPV_nolen(_devname) : NULL;
		char *ret;
	CODE:
		RETVAL = NULL;
		if (tagname && devname) {
			RETVAL = blkid_get_tag_value(cache, tagname, devname);
		}
	OUTPUT:
		RETVAL

		

### extern char *blkid_get_devname(blkid_cache cache, const char *token,
### 			       const char *value);

char *
blkid_get_devname(_cache, _token, ...)
	SV *_cache
	SV *_token
	PREINIT:
		SV *_value = NULL;
		blkid_cache cache = sv2cache(_cache, "blkid_get_tag_value");
		char *token = (SvOK(_token) && SvPOK(_token)) ? SvPV_nolen(_token) : NULL;
		char *value = NULL;
		char *ret = NULL;
		SV *_ret = NULL;
	CODE:
		if (items > 3) {
			Perl_croak(aTHX_ "Usage: Device::Blkid::blkid_get_devname(_cache, _token, _value)");
		} else if (items == 3) {
			_value = ST(2);
			if (SvOK(_value) && SvPOK(_value)) {
				value = SvPV_nolen(_value);
			}
		}
		RETVAL = NULL;
		if (cache && token) {
			RETVAL = blkid_get_devname(cache, token, value);
		}
	OUTPUT:
		RETVAL
		


### 
### /* tag.c */
### extern blkid_tag_iterate blkid_tag_iterate_begin(blkid_dev dev);

SV *
blkid_tag_iterate_begin(_dev)
	SV *_dev
	INIT:
		blkid_dev dev = sv2dev(_dev, "blkid_tag_iterate_begin");
		blkid_tag_iterate tag_iterate = NULL;
		SV *_tag_iterate;
	PPCODE:
		if (dev) {
			tag_iterate = blkid_tag_iterate_begin(dev);
		}

		if (tag_iterate) {
			_tag_iterate = sv_newmortal();
			sv_setref_pv(_tag_iterate, "Device::Blkid::TagIterate", (void *)tag_iterate);
			SvREADONLY_on(SvRV(_tag_iterate));
			XPUSHs(_tag_iterate);
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern int blkid_tag_next(blkid_tag_iterate iterate,
### 			      const char **type, const char **value);

SV *
blkid_tag_next(_iterate)
	SV *_iterate
	INIT:
		blkid_tag_iterate iterate = sv2tag_iterate(_iterate, "blkid_tag_next");
		const char *type;
		const char *value;

		HV *rh;
		int ret;
	PPCODE:
		if (iterate) {
			ret = blkid_tag_next(iterate, &type, &value);
			if (type && value && (ret == 0)) {

				rh = (HV *)sv_2mortal((SV *)newHV());

				hv_store(rh, "type", 4, newSVpv(type, 0), 0);
				hv_store(rh, "value", 5, newSVpv(value, 0), 0);

				XPUSHs(sv_2mortal(newRV((SV *) rh)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern void blkid_tag_iterate_end(blkid_tag_iterate iterate);
# Object destructor calls _DO_... function below
void
blkid_tag_iterate_end(_iterate)
	SV *_iterate
	INIT:
		blkid_tag_iterate iterate = sv2tag_iterate(_iterate, "blkid_tag_iterate_end");
	CODE:
		if (iterate) {
			sv_setsv(_iterate, &PL_sv_undef);
		}


void
_DO_blkid_tag_iterate_end(_iterate)
	SV *_iterate
	INIT:
		blkid_tag_iterate iterate = sv2tag_iterate(_iterate, "blkid_tag_iterate_end");
	CODE:
		if (iterate) {
			blkid_tag_iterate_end(iterate);
		}

### extern int blkid_dev_has_tag(blkid_dev dev, const char *type,
### 			     const char *value);

IV
blkid_dev_has_tag(_dev, type, value)
	SV *_dev
	const char *type
	const char *value
	INIT:
		blkid_dev dev = sv2dev(_dev, "blkid_dev_has_tag");
	CODE:
		/* blkid_dev_has_tag does NOT accept empty value (and "LABEL=foo" type) */
		if (dev && type && value) {
			RETVAL = blkid_dev_has_tag(dev, type, value);
		} else {
			RETVAL = 0;
		}
	OUTPUT:
		RETVAL
	

### extern blkid_dev blkid_find_dev_with_tag(blkid_cache cache,
### 					 const char *type,
### 					 const char *value);

SV *
blkid_find_dev_with_tag(_cache, type, value)
	SV *_cache
	const char *type
	const char *value
	INIT:
		blkid_cache cache = sv2cache(_cache, "blkid_find_dev_with_tag");
		blkid_dev dev = NULL;
		SV *_dev = NULL;
	PPCODE:
		if (cache) {
			dev = blkid_find_dev_with_tag(cache, type, value);
		}

		if (dev) {
			_dev = sv_newmortal();
			sv_setref_pv(_dev, "Device::Blkid::Device", (void *)dev);
			SvREADONLY_on(SvRV(_dev));
			XPUSHs(_dev);
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern int blkid_parse_tag_string(const char *token, char **ret_type,
### 				  char **ret_val);

SV *
blkid_parse_tag_string(token)
	const char *token
	INIT:
		char *ret_type;
		char *ret_val;

		HV *rh;

		int ret;
	PPCODE:
		if (token) {
			ret = blkid_parse_tag_string(token, &ret_type, &ret_val);
			if (ret == 0 && ret_type && ret_val) {

				rh = (HV *)sv_2mortal((SV *)newHV());

				hv_store(rh, "type", 4, newSVpv(ret_type, 0), 0);
				hv_store(rh, "value", 5, newSVpv(ret_val, 0), 0);

				XPUSHs(sv_2mortal(newRV((SV *) rh)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}

### 
### /* version.c */
### extern int blkid_parse_version_string(const char *ver_string);

int
blkid_parse_version_string(ver_string)
	const char *ver_string

### extern int blkid_get_library_version(const char **ver_string,
### 				     const char **date_string);
### 

SV *
blkid_get_library_version()
	INIT:
		const char *ver_string;
		const char *date_string;
		HV *rh;
		int ret;
	PPCODE:
		ret = blkid_get_library_version(&ver_string, &date_string);

		rh = (HV *)sv_2mortal((SV *)newHV());

		hv_store(rh, "int", 3, newSViv(ret), 0);

		if (ver_string && date_string) {


			hv_store(rh, "ver", 3, newSVpv(ver_string, 0), 0);
			hv_store(rh, "date", 4, newSVpv(date_string, 0), 0);

		}

		XPUSHs(sv_2mortal(newRV((SV *) rh)));


### /* encode.c */
### extern int blkid_encode_string(const char *str, char *str_enc, size_t len);
# // TODO: derive string length from input. What does this function do anyways?

SV *
blkid_encode_string(str)
	const char *str
	INIT:
		char str_enc[1024];

		int ret;
	PPCODE:
		ret = blkid_encode_string(str, str_enc, 1023);
		if (ret != 0) {
			XPUSHs(&PL_sv_undef);
		} else {
			XPUSHs(sv_2mortal(newSVpv(str_enc, 0)));
		}


### extern int blkid_safe_string(const char *str, char *str_safe, size_t len);
# // TODO: derive string length from input. What does this function do anyways?

SV *
blkid_safe_string(str)
	const char *str
	INIT:
		char str_safe[1024];

		int ret;
	PPCODE:
		ret = blkid_safe_string(str, str_safe, 1023);
		if (ret != 0) {
			XPUSHs(&PL_sv_undef);
		} else {
			XPUSHs(sv_2mortal(newSVpv(str_safe, 0)));
		}



### /* evaluate.c */
### extern int blkid_send_uevent(const char *devname, const char *action);

int
blkid_send_uevent(devname, action)
	const char *devname
	const char *action
	INIT:
		int ret;
	PPCODE:
		if (devname && action) {
			ret = blkid_send_uevent(devname, action);
			/* Reverse logic -- ret val. 0 is good! */
			if (ret == 0) {
				XPUSHs(sv_2mortal(newSViv(1)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}

### extern char *blkid_evaluate_tag(const char *token, const char *value,
### 				blkid_cache *cache);


SV *
blkid_evaluate_tag(token, value, ...)
	const char *token
	const char *value
	INIT:
		char *ret;
		SV *_cache = NULL;
		blkid_cache cache = NULL;
		blkid_cache *cachep = NULL;
	PPCODE:
		if (items > 3) {
			Perl_croak(aTHX_ "Usage: Device::Blkid::blkid_evaluate_tag(token, value)");
		}
		if (items == 3) {
			_cache = ST(2);
			if (SvOK(_cache)) {
				cache = sv2cache(_cache, "blkid_evaluate_tag");
				cachep = &cache; /* WTF??? */
			}
		}
		if (token && value) {
			ret = blkid_evaluate_tag(token, value, cachep);
			XPUSHs(sv_2mortal(newSVpv(ret, 0)));
			free(ret);
		} else {
			XPUSHs(&PL_sv_undef);
		}



### /* probe.c */
### extern int blkid_known_fstype(const char *fstype);

int
blkid_known_fstype(fstype)
	const char *fstype

### extern blkid_probe blkid_new_probe(void);

SV *
blkid_new_probe()
	INIT:
		blkid_probe probe = NULL;
		SV *_probe;
	PPCODE:
		probe = blkid_new_probe();
		if (probe) {
			_probe = sv_newmortal();
			sv_setref_pv(_probe, "Device::Blkid::Probe", (void *)probe);
			SvREADONLY_on(SvRV(_probe));
			XPUSHs(_probe);
		} else {
			XPUSHs(&PL_sv_undef);
		}

### extern void blkid_free_probe(blkid_probe pr);

void
blkid_free_probe(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_free_probe");
	CODE:
		if (pr) {
			blkid_free_probe(pr);
		}

### extern void blkid_reset_probe(blkid_probe pr);

void
blkid_reset_probe(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_reset_probe");
	CODE:
		if (pr) {
			blkid_reset_probe(pr);
		}


### extern int blkid_probe_set_device(blkid_probe pr, int fd,
### 	                blkid_loff_t off, blkid_loff_t size);

int
blkid_probe_set_device(_pr, fd, off, size)
	SV *_pr
	int fd
	int64_t off
	int64_t size
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_set_device");
	CODE:
		if (pr) {
			RETVAL = blkid_probe_set_device(pr, fd, off, size);
		} else {
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

		
	

### extern int blkid_probe_set_request(blkid_probe pr, int flags);

int
blkid_probe_set_request(_pr, flags)
	SV *_pr
	int flags
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_set_request");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}

		RETVAL = blkid_probe_set_request(pr, flags);

	OUTPUT:
		RETVAL


### extern int blkid_probe_filter_usage(blkid_probe pr, int flag, int usage);


int
blkid_probe_filter_usage(_pr, flag, usage)
	SV *_pr
	int flag
	int usage
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_filter_usage");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}

		RETVAL = blkid_probe_filter_usage(pr, flag, usage);

	OUTPUT:
		RETVAL
	

### extern int blkid_probe_filter_types(blkid_probe pr,
### 			int flag, char *names[]);

# // TODO XXX TODO XXX Segfaults :(

int
blkid_probe_filter_types(_pr, flag, _names)
	SV *_pr
	int flag
	AV *_names
	PREINIT:
		char **names;
		I32 num; 
		blkid_probe pr;
		int i;
		int ok;
		SV **_s;
		char *s;
	INIT:
		pr = sv2probe(_pr, "blkid_probe_filter_types");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		num = av_len(_names) + 1;
		if (num < 1) {
			XSRETURN_UNDEF;
		}
		names = malloc(sizeof(char *) * num);
		for (i = 0; i < num; i++) {
			ok = 0;
			_s = av_fetch(_names, i, 0);
			if (_s) {
				if (SvOK(*_s)) {
					if (SvPOK(*_s)) {
						ok = 1;
						s = SvPV_nolen(*_s);
					}
				}
			}

			if (ok) {
				names[i] = s;
			} else {
				names[i] = ""; //  XXX or rather NULL?
			}
		}

		for (i = 0; i < num; i++) {
			printf("name %d is %s\n", i, names[i]);
		}

		RETVAL = blkid_probe_filter_types(pr, flag, names);

		free(names);
	OUTPUT:
		RETVAL


### extern int blkid_probe_invert_filter(blkid_probe pr);

int
blkid_probe_invert_filter(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_invert_filter");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_probe_invert_filter(pr);
	OUTPUT:
		RETVAL

### extern int blkid_probe_reset_filter(blkid_probe pr);

int
blkid_probe_reset_filter(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_reset_filter");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_probe_reset_filter(pr);
	OUTPUT:
		RETVAL


### extern int blkid_do_probe(blkid_probe pr);

int
blkid_do_probe(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_do_probe");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_do_probe(pr);
	OUTPUT:
		RETVAL




### extern int blkid_do_safeprobe(blkid_probe pr);

int
blkid_do_safeprobe(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_do_safeprobe");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_do_safeprobe(pr);
	OUTPUT:
		RETVAL


### extern int blkid_probe_numof_values(blkid_probe pr);

int
blkid_probe_numof_values(_pr)
	SV *_pr
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_numof_values");
	CODE:
		if (!pr) {
			XSRETURN_UNDEF;
		}
		RETVAL = blkid_probe_numof_values(pr);
	OUTPUT:
		RETVAL


### extern int blkid_probe_get_value(blkid_probe pr, int num, const char **name,
###                         const char **data, size_t *len);

SV *
blkid_probe_get_value(_pr, num)
	SV *_pr
	int num
	INIT:
		HV *rh = NULL;
		const char *name;
		const char *data;
		size_t len;
		int ret;

		blkid_probe pr = sv2probe(_pr, "blkid_probe_get_value");
	PPCODE:
		if (pr) {
			ret = blkid_probe_get_value(pr, num, &name, &data, &len);

			if (ret == 0) {
				rh = (HV *)sv_2mortal((SV *)newHV());

				hv_store(rh, "name", 4, newSVpv(name, 0), 0);
				hv_store(rh, "data", 4, newSVpv(data, 0), 0);

				XPUSHs(sv_2mortal(newRV((SV *) rh)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}



### extern int blkid_probe_lookup_value(blkid_probe pr, const char *name,
###                         const char **data, size_t *len);

SV *
blkid_probe_lookup_value(_pr, name)
	SV *_pr
	const char *name
	INIT:
		const char *data;
		size_t len;
		int ret;
		SV *_data;

		blkid_probe pr = sv2probe(_pr, "blkid_probe_lookup_value");
	PPCODE:
		if (pr) {
			if (blkid_probe_lookup_value(pr, name, &data, &len) == 0) {
				XPUSHs(sv_2mortal(newSVpv(data, len)));
			} else {
				XPUSHs(&PL_sv_undef);
			}
		} else {
			XPUSHs(&PL_sv_undef);
		}


### extern int blkid_probe_has_value(blkid_probe pr, const char *name);

int
blkid_probe_has_value(_pr, name)
	SV *_pr
	const char *name
	INIT:
		blkid_probe pr = sv2probe(_pr, "blkid_probe_has_value");
	CODE:
		if (pr) {
			RETVAL = blkid_probe_has_value(pr, name);
		} else {
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL
