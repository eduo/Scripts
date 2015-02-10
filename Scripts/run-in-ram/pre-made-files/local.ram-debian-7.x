# Local filesystem mounting			-*- shell-script -*-

pre_mountroot()
{
	[ "$quiet" != "y" ] && log_begin_msg "Running /scripts/local-top"
	run_scripts /scripts/local-top
	[ "$quiet" != "y" ] && log_end_msg

	wait_for_udev 10

	# Load ubi with the correct MTD partition and return since fstype
	# doesn't work with a char device like ubi.
	if [ -n "$UBIMTD" ]; then
		modprobe ubi mtd=$UBIMTD
		return
	fi

	# Don't wait for a root device that doesn't have a corresponding
	# device in /dev (ie, mtd0)
	if [ "${ROOT#/dev}" = "${ROOT}" ]; then
		return
	fi

	# If the root device hasn't shown up yet, give it a little while
	# to deal with removable devices
	if [ ! -e "${ROOT}" ] || ! $(get_fstype "${ROOT}" >/dev/null); then
		log_begin_msg "Waiting for root file system"

		# Default delay is 30s
		slumber=${ROOTDELAY:-30}

		slumber=$(( ${slumber} * 10 ))
		while [ ! -e "${ROOT}" ] \
		|| ! $(get_fstype "${ROOT}" >/dev/null); do
			/bin/sleep 0.1
			slumber=$(( ${slumber} - 1 ))
			[ ${slumber} -gt 0 ] || break
		done

		if [ ${slumber} -gt 0 ]; then
			log_end_msg 0
		else
			log_end_msg 1 || true
		fi
	fi

	# We've given up, but we'll let the user fix matters if they can
	while [ ! -e "${ROOT}" ]; do
		# give hint about renamed root
		case "${ROOT}" in
		/dev/hd*)
			suffix="${ROOT#/dev/hd}"
			major="${suffix%[[:digit:]]}"
			major="${major%[[:digit:]]}"
			if [ -d "/sys/block/sd${major}" ]; then
				echo "WARNING bootdevice may be renamed. Try root=/dev/sd${suffix}"
			fi
			;;
		/dev/sd*)
			suffix="${ROOT#/dev/sd}"
			major="${suffix%[[:digit:]]}"
			major="${major%[[:digit:]]}"
			if [ -d "/sys/block/hd${major}" ]; then
				echo "WARNING bootdevice may be renamed. Try root=/dev/hd${suffix}"
			fi
			;;
		esac
		echo "Gave up waiting for root device.  Common problems:"
		echo " - Boot args (cat /proc/cmdline)"
		echo "   - Check rootdelay= (did the system wait long enough?)"
		echo "   - Check root= (did the system wait for the right device?)"
		echo " - Missing modules (cat /proc/modules; ls /dev)"
		panic "ALERT!  ${ROOT} does not exist.  Dropping to a shell!"
	done
}

mountroot()
{
	pre_mountroot

	# Get the root filesystem type if not set
	if [ -z "${ROOTFSTYPE}" ]; then
		FSTYPE=$(get_fstype "${ROOT}")
	else
		FSTYPE=${ROOTFSTYPE}
	fi

	[ "$quiet" != "y" ] && log_begin_msg "Running /scripts/local-premount"
	run_scripts /scripts/local-premount
	[ "$quiet" != "y" ] && log_end_msg

	if [ "${readonly}" = "y" ]; then
		roflag=-r
	else
		roflag=-w
	fi

	# FIXME This has no error checking
	modprobe ${FSTYPE}

	# FIXME This has no error checking
	# Mount root
	if [ "${FSTYPE}" != "unknown" ]; then
		#mount ${roflag} -t ${FSTYPE} ${ROOTFLAGS} ${ROOT} ${rootmnt}
# RUN-IN-RAM    
mkdir /ramboottmp
mount ${roflag} -t ${FSTYPE} ${ROOTFLAGS} ${ROOT} /ramboottmp
mount -t tmpfs -o size=100% none ${rootmnt}
cd ${rootmnt}
cp -rfa /ramboottmp/* ${rootmnt}
umount /ramboottmp
    
	else
		mount ${roflag} ${ROOTFLAGS} ${ROOT} ${rootmnt}
	fi

	[ "$quiet" != "y" ] && log_begin_msg "Running /scripts/local-bottom"
	run_scripts /scripts/local-bottom
	[ "$quiet" != "y" ] && log_end_msg
}
