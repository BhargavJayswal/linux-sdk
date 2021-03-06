#!/bin/sh

# rpkg-build -- construct a .rpk from a directory
# huangzhangliang
# based on a script by OpenWrt

set -e

version=1.0
FIND="$(which find)"
FIND="${FIND:-$(which gfind)}"
TAR="${TAR:-$(which tar)}"

rpkg_extract_value() {
	sed -e "s/^[^:]*:[[:space:]]*//"
}

required_field() {
	field=$1

	value=`grep "^$field:" < $CONTROL/control | rpkg_extract_value`
	if [ -z "$value" ]; then
		echo "*** Error: $CONTROL/control is missing field $field" >&2
		return 1
	fi
	echo $value
	return 0
}

disallowed_field() {
	field=$1

	value=`grep "^$field:" < $CONTROL/control | rpkg_extract_value`
	if [ -n "$value" ]; then
		echo "*** Error: $CONTROL/control contains disallowed field $field" >&2
		return 1
	fi
	echo $value
	return 0
}

pkg_appears_sane() {
	local pkg_dir=$1

	local owd=$PWD
	cd $pkg_dir

	PKG_ERROR=0

	cvs_dirs=`$FIND . -name 'CVS'`
	if [ -n "$cvs_dirs" ]; then
	    if [ "$noclean" = "1" ]; then
		echo "*** Warning: The following CVS directories where found.
You probably want to remove them: " >&2
		ls -ld $cvs_dirs
		echo >&2
	    else
		echo "*** Removing the following files: $cvs_dirs"
		rm -rf "$cvs_dirs"
	    fi
	fi

	tilde_files=`$FIND . -name '*~'`
	if [ -n "$tilde_files" ]; then
	    if [ "$noclean" = "1" ]; then
		echo "*** Warning: The following files have names ending in '~'.
You probably want to remove them: " >&2
		ls -ld $tilde_files
		echo >&2
	    else
		echo "*** Removing the following files: $tilde_files"
		rm -f "$tilde_files"
	    fi
	fi

	large_uid_files=`$FIND . -uid +99 || true`

	if [ "$ogargs" = "" ]  && [ -n "$large_uid_files" ]; then
		echo "*** Warning: The following files have a UID greater than 99.
You probably want to chown these to a system user: " >&2
		ls -ld $large_uid_files
		echo >&2
	fi
	    

	if [ ! -f "$CONTROL/control" ]; then
		echo "*** Error: Control file $pkg_dir/$CONTROL/control not found." >&2
		cd $owd
		return 1
	fi

	pkg=`required_field Package`
	[ "$?" -ne 0 ] && PKG_ERROR=1

	version=`required_field Version | sed 's/Version://; s/^.://g;'`
	[ "$?" -ne 0 ] && PKG_ERROR=1

	platform=`required_field Platform`
	[ "$?" -ne 0 ] && PKG_ERROR=1

	required_field Description >/dev/null
	[ "$?" -ne 0 ] && PKG_ERROR=1	

	disallowed_filename=`disallowed_field Filename`
	[ "$?" -ne 0 ] && PKG_ERROR=1

	if echo $pkg | grep '[^a-zA-Z0-9_.+-]'; then
		echo "*** Error: Package name $name contains illegal characters, (other than [a-z0-9.+-])" >&2
		PKG_ERROR=1;
	fi

	local bad_fields=`sed -ne 's/^\([^[:space:]][^:[:space:]]\+[[:space:]]\+\)[^:].*/\1/p' < $CONTROL/control | sed -e 's/\\n//'`
	if [ -n "$bad_fields" ]; then
		bad_fields=`echo $bad_fields`
		echo "*** Error: The following fields in $CONTROL/control are missing a ':'" >&2
		echo "	$bad_fields" >&2
		echo "rpkg-build: This may be due to a missing initial space for a multi-line field value" >&2
		PKG_ERROR=1
	fi

	for script in $CONTROL/preinst $CONTROL/postinst $CONTROL/prerm $CONTROL/postrm; do
		if [ -f $script -a ! -x $script ]; then
		    if [ "$noclean" = "1" ]; then
			echo "*** Error: package script $script is not executable" >&2
			PKG_ERROR=1
		    else
			chmod a+x $script
		    fi
		fi
	done

	if [ -f $CONTROL/conffiles ]; then
		rm -f $CONTROL/conffiles.resolved

		for cf in `$FIND $(sed -e "s!^/!$pkg_dir/!" $CONTROL/conffiles) -type f`; do
			echo "${cf#$pkg_dir}" >> $CONTROL/conffiles.resolved
		done

		rm $CONTROL/conffiles
		mv $CONTROL/conffiles.resolved $CONTROL/conffiles
		chmod 0644 $CONTROL/conffiles
	fi

	cd $owd
	return $PKG_ERROR
}

###
# rpkg-build "main"
###
ogargs=""
outer=ar
noclean=0
usage="Usage: $0 [-c] [-C] [-o owner] [-g group] <pkg_directory> [<destination_directory>]"
while getopts "cg:ho:v" opt; do
    case $opt in
	o ) owner=$OPTARG
	    ogargs="--owner=$owner"
	    ;;
	g ) group=$OPTARG
	    ogargs="$ogargs --group=$group"
	    ;;
        c ) outer=$TAR
            ;;
        C ) noclean=1
            ;;
	v ) echo $version
	    exit 0
	    ;;
	h ) 	echo $usage  >&2 ;;
	\? ) 	echo $usage  >&2
	esac
done


shift $(($OPTIND - 1))

# continue on to process additional arguments

case $# in
1)
	dest_dir=$PWD
	;;
2)
	dest_dir=$2
	if [ "$dest_dir" = "." -o "$dest_dir" = "./" ] ; then
	    dest_dir=$PWD
	fi
	;;
*)
	echo $usage >&2
	exit 1 
	;;
esac

pkg_dir=$1

if [ ! -d $pkg_dir ]; then
	echo "*** Error: Directory $pkg_dir does not exist" >&2
	exit 1
fi

# CONTROL is second so that it takes precedence
CONTROL=
[ -d $pkg_dir/CONTROL ] && CONTROL=CONTROL
if [ -z "$CONTROL" ]; then
	echo "*** Error: Directory $pkg_dir has no CONTROL subdirectory." >&2
	exit 1
fi

if ! pkg_appears_sane $pkg_dir; then
	echo >&2
	echo "rpkg-build: Please fix the above errors and try again." >&2
	exit 1
fi

tmp_dir=$dest_dir/IPKG_BUILD.$$
mkdir $tmp_dir

echo $CONTROL > $tmp_dir/tarX
# Preserve permissions (-p) when creating data.tar.gz as non-root user
( cd $pkg_dir && $TAR $ogargs -X $tmp_dir/tarX --format=gnu -czpf $tmp_dir/data.tar.gz . )

installed_size=`stat -c "%s" $tmp_dir/data.tar.gz`
sed -i -e "s/^Installed-Size: .*/Installed-Size: $installed_size/" \
	$pkg_dir/$CONTROL/control

( cd $pkg_dir/$CONTROL && $TAR $ogargs --format=gnu -czf $tmp_dir/control.tar.gz . )
rm $tmp_dir/tarX

pkg_file=$dest_dir/${pkg}_${version}_${platform}.rpk
rm -f $pkg_file
( cd $tmp_dir && $TAR --format=gnu -zcf $pkg_file ./data.tar.gz ./control.tar.gz )

rm $tmp_dir/data.tar.gz $tmp_dir/control.tar.gz
rmdir $tmp_dir

echo "Packaged contents of $pkg_dir into $pkg_file"
