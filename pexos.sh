#!/bin/bash -
#===============================================================================
#
#          FILE: pexos.sh
#
#         USAGE: ./pexos.sh
#
#   DESCRIPTION:
#
#       LICENCE: GPLv2, see included file LICENCE
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Robin "tschaerni" "bunkerotter" Cerny (rc), robin@cerny.li
#  ORGANIZATION:
#       CREATED: 01.06.2018 17:00
#      REVISION: ---
#-------------------------------------------------------------------------------
#    pexos - a simple bash-based management tool for syslinux pxe environments
#    Copyright (C) 2018  Robin Cerny
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#===============================================================================


# read configfile
# todo: dir finding, basenamestuff etc...
source "pexos.cfg"

IMAGEPATH="$2"								# i.e: /path/imagename.iso
IMAGEFILENAME="${IMAGEPATH##*/}"			# i.e: imagename.iso
IMAGENAME="${IMAGEFILENAME%.*}"				# i.e: imagename


status_message(){
#
#	usage:
#	status_message "<arg1>" "<arg2>"
#	arg1: displayed message
#	arg2: can be either of {ok|done|fail}
#
#	known bug: if the message is longer than the terminals width the output is fucked up
#
	# colors
	RESET="\e[0m"
	RED="\e[31m"
	GREEN="\e[32m"
	ORANGE="\e[33m"

	MSG="$1"
	MSGLENGTH="${#MSG}"
	TERMCOLS="$(tput cols)"
	OKMSG="[  ${GREEN}OK${RESET}  ]"
	DONEMSG="[ ${GREEN}DONE${RESET} ]"
	FAILMSG="[ ${RED}FAIL${RESET} ]"
	WARNMSG="[ ${ORANGE}WARN${RESET} ]"
	MVCURSOR="$(( TERMCOLS - 10 ))"

	case "$2" in
		"ok")
			STATUSMSG="$OKMSG"
			;;
		"done")
			STATUSMSG="$DONEMSG"
			;;
		"warn")
			STATUSMSG="$WARNMSG"
			;;
		"fail")
			STATUSMSG="$FAILMSG"
			;;
	esac

	echo "$MSG"
	tput cuu1
	tput cuf $MVCURSOR
	echo -e "$STATUSMSG"
}

check_isoimage(){
	if [[ "${IMAGEFILENAME##*.}" = "iso" ]]
	then
		status_message "validate imagefile" "ok"
	else
		status_message "validate imagefile" "fail"
		echo "not a valid ISO image or path"
		exit 1
	fi
}

check_dir(){
	DIR="$1"
	if [[ -d "$DIR" ]]
	then
			if [[ -w "$DIR" ]]
			then
					status_message "check directory $DIR" "ok"
			else
					status_message "check directory $DIR" "fail"
					echo "error: directory $DIR is not writable"
					exit 1
			fi
	else
			if RETURNMSG="$(mkdir -p "$DIR" 2>&1)"
			then
					status_message "check directory $DIR" "ok"
			else
					status_message "check directory $DIR" "fail"
					echo "error: $RETURNMESSAGE"
					exit 1
			fi
	fi
}

check_cp(){
	cp "$1" "$2"
	if RETURNMSG="$(cp $1 $2 2>&1)"
	then
		status_message "copying file $1 to $2" "done"
	else
		status_message "copying file $1 to $2" "fail"
		echo "error: $RETURNMSG"
		exit 1
	fi
}

identify_distro(){
	case "$1" in
		*linuxmint*)
			DISTRO="linuxmint"
			TEMPLATE="$TEMPLATEDIR/linuxmint_pxe_template.cfg"
			;;
		*ubuntu*)
			DISTRO="ubuntu"
			TEMPLATE="$TEMPLATEDIR/ubuntu_pxe_template.cfg"
			;;
		*debian*)
			DISTRO="debian"
			TEMPLATE="$TEMPLATEDIR/debian_pxe_template.cfg"
			;;
		*)
			status_message "can't identify linux distro / or given distro isn't supported yet" "fail"
			exit 1
			;;
	esac

	case "$1" in
		*amd64*|*64bit*)
			ARCH="64bit"
			;;
		*i386*|*i586*|*i686*|*32bit*)
			ARCH="32bit"
			;;
		*)
			status_message "can't identify architecture of given iso" "fail"
			exit 1
		;;
	esac

	case "$1" in
		*budgie*)
			GUIFLAVOR="budgie"
			;;
		*cinnamon*)
			GUIFLAVOR="cinnamon"
			;;
		*mate*)
			GUIFLAVOR="mate"
			;;
		*lxde*|*lubuntu*)
			GUIFLAVOR="lxde"
			;;
		*xfce*|*xubuntu*)
			GUIFLAVOR="xfce"
			;;
		*kde*|*kubuntu*)
			GUIFLAVOR="kde"
			;;
		*gnome*|ubuntu*)
			GUIFLAVOR="gnome"
			;;
		*)
			status_message "can't identify used Desktop Environment" "fail"
			exit 1
			;;
	esac

	status_message "image identified: $DISTRO $ARCH $GUIFLAVOR" "done"

	PXECONF="$PXECONFDIR/$DISTRO/$IMAGENAME.cfg"
	ISO="$ISODIR/$DISTRO/$IMAGEFILENAME"
	ISOMOUNT="$ISOMOUNTDIR/$DISTRO/$IMAGENAME"
	KERNELDIR="$TFTPDIR/$DISTRO/$IMAGENAME"
	INITRDDIR="$TFTPDIR/$DISTRO/$IMAGENAME"

	KERNEL="::/$DISTRO/$IMAGENAME/vmlinuz"
	INITRD="::/$DISTRO/$IMAGENAME/initrd.lz"
	NFSROOT="$TFTPIP:$ISOMOUNT"
}

check_directories(){
	check_dir "$PXECONFDIR/$DISTRO"
}

move_imagefile(){
	check_dir "$ISODIR/$DISTRO"

	if ! [[ -f "$ISO" ]]
	then
		mv "$IMAGEPATH" "$ISO"
		if [[ "$?" = "0" ]]
		then
			status_message "moving $IMAGEPATH to $ISO" "done"
		else
			status_message "moving $IMAGEPATH to $ISO" "fail"
			echo "error: couldn't move $IMAGEPATH to $ISO"
			exit 1
		fi
	fi
}

copy_kernelfiles(){
	check_dir "$KERNELDIR"
	check_dir "$INITRDDIR"
	case "$DISTRO" in
		linuxmint|ubuntu)
			check_cp $(find "$ISOMOUNT/casper" -type f -name vmlinuz*) "$KERNELDIR/vmlinuz"
			check_cp $(find "$ISOMOUNT/casper" -type f -name initrd.lz*) "$INITRDDIR/initrd.lz"
			;;
		debian)
			check_cp $(find "$ISOMOUNT/live" -type f -name vmlinuz*) "$KERNELDIR/vmlinuz"
			check_cp $(find "$ISOMOUNT/live" -type f -name initrd.img*) "$INITRDDIR/initrd.img"
			;;
	esac
}

remove_kernelfiles(){
	if RETURNMSG="$(rm -r $KERNELDIR 2>&1)"
	then
		status_message "removing $KERNELDIR" "done"
	else
		status_message "removing $KERNELDIR" "fail"
		echo "error: $RETURNMSG"
	fi
	if [[ -d "$INITRDDIR" ]]
	then
		if RETURNMSG="$( rm -r $INITRDDIR 2>&1)"
		then
			status_message "removing $INITRDDIR" "done"
		else
			status_message "removing $INITRDDIR" "fail"
			echo "error: $RETURNMSG"
		fi
	fi
}

generate_pxeconfig(){
	sed -e "/#.*$/d" \
			-e "s/GUIFLAVOR/${GUIFLAVOR//\//\\/}/g" \
			-e "s/ARCH/${ARCH//\//\\/}/g" \
			-e "s/KERNELFILE/${KERNEL//\//\\/}/g" \
			-e "s/INITRDFILE/${INITRD//\//\\/}/g" \
			-e "s/NFSROOT/${NFSROOT//\//\\/}/g" \
			"$TEMPLATE" > "$PXECONF"
	if [[ "$?" = "0" ]]
	then
		status_message "generating pxeconfig $PXECONF" "done"
	else
		status_message "generating pxeconfig $PXECONF" "fail"
		exit 1
	fi
}

generate_pxemenu(){
#	usage: generate_pxemenu <arg1>
#	arg1: distroname {debian|ubuntu|linuxmint}
	PXEMENU="$PXECONFDIR/$1/${1}_menu.cfg"
#	find config files of distro <arg1> and sort them in humanreadable order and reverse
#	(with that the newer versions of the same iso will be on top)
	cat $(find "$PXECONFDIR/$1" -type f -name "*.cfg" | egrep -v "*_menu.cfg" | sort -hr) > "$PXEMENU"
	if [[ "$?" = "0" ]]
	then
		status_message "generating $PXEMENU" "done"
	else
		status_message "generating $PXEMENU" "fail"
		echo "error: generating $PXEMENU"
		exit 1
	fi
}

remove_pxeconfig(){
	if RETURNMSG="$(rm $PXECONF 2>&1)"
	then
		status_message "removing $PXECONF" "done"
	else
		status_message "removing $PXECONF" "fail"
		echo "error: $RETURNMSG"
		exit 1
	fi
}

add_fstab(){
	check_dir "$ISOMOUNT"

	if grep "$IMAGEFILENAME" "$FSTAB" > /dev/null 2>&1
	then
		status_message "found existing fstab entry for $IMAGEFILENAME" "fail"
		exit 1
	fi
	check_cp "$FSTAB" "$FSTAB.bak" &&
	echo -e "$ISO\t\t$ISOMOUNT\t\tiso9660\tloop" >> "$FSTAB"
	if [[ "$?" = "0" ]]
	then
		status_message "adding fstab entry" "done"
	else
		status_message "adding fstab entry" "fail"
		echo "error: couldn't create mount entry in $FSTAB"
		exit 1
	fi
}

remove_fstab(){
	check_cp "$FSTAB" "$FSTAB.bak" &&
	if grep "$IMAGEFILENAME" "$FSTAB" > /dev/null 2>&1
	then
		status_message "searching $FSTAB" "ok"
		sed -i "/${IMAGEFILENAME//\//\\/}/d" "$FSTAB"
		if [[ "$?" = "0" ]]
		then
			status_message "removing $IMAGEFILENAME entry in $FSTAB" "done"
		else
			status_message "removing $IMAGEFILENAME entry in $FSTAB" "fail"
			echo "error: couldn't remove mount entry from $FSTAB"
			exit 1
		fi
	else
		status_message "searching $FSTAB" "false"
		echo "error: couldn't find mount entry in $FSTAB"
		exit 1
	fi
}

mount_image(){
	case "$1" in
		mount_iso)
			RETURNMSG="$(mount $ISOMOUNT 2>&1)"
			if [[ "$?" = "0" ]]
			then
				status_message "mounting $ISO to mountpoint $ISOMOUNT" "done"
			else
				status_message "mounting $ISO to mountpoint $ISOMOUNT" "fail"
				echo "error: $RETURNMSG" 
			fi
			;;

		umount_iso)
			RETURNMSG="$(umount $ISOMOUNT 2>&1)"
			if [[ "$?" = "0" ]]
			then
				status_message "unmounting $ISO at mountpoint $ISOMOUNT" "done"
			else
				status_message "unmounting $ISO at mountpoint $ISOMOUNT" "fail"
				echo "error: $RETURNMSG"
			fi
			;;
	esac
}

# for fstab deletion: sed '/debian-live-.*-amasdasdd64-xfce.iso/d' /etc/fstab
#generate_config
case "$1" in
	add)
		check_isoimage
		sleep 0.2
		identify_distro "$IMAGEFILENAME"
		sleep 0.2
		check_directories
		sleep 0.2
		move_imagefile
		sleep 0.2
		add_fstab
		sleep 0.2
		mount_image mount_iso
		sleep 0.2
		copy_kernelfiles
		sleep 0.2
		generate_pxeconfig
		sleep 0.2
		generate_pxemenu "$DISTRO"
		;;
	remove)
		check_isoimage
		sleep 0.2
		identify_distro "$IMAGEFILENAME"
		sleep 0.2
		remove_pxeconfig
		sleep 0.2
		mount_image umount_iso
		sleep 0.2
		remove_fstab
		sleep 0.2
		remove_kernelfiles
		sleep 0.2
		generate_pxemenu "$DISTRO
		sleep 0.2"
		echo "I don't remove images atm, you have to do it your self ;)"
		echo ""
		sleep 2
		echo "I'm done"
		;;
	help|-h)
		echo "ask Robin"
		;;
	*)
		echo "not implemented"
		;;
esac



exit 0
