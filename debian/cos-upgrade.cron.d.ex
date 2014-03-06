#
# Regular cron jobs for the cos-upgrade package
#
0 4	* * *	root	[ -x /usr/bin/cos-upgrade_maintenance ] && /usr/bin/cos-upgrade_maintenance
