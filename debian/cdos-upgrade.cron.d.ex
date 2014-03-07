#
# Regular cron jobs for the cdos-upgrade package
#
0 4	* * *	root	[ -x /usr/bin/cdos-upgrade_maintenance ] && /usr/bin/cdos-upgrade_maintenance
