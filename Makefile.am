ACLOCAL_AMFLAGS = -I m4
SUBDIRS = src

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = ipiped-1.1.pc

dbusdir=$(datadir)/dbus-1/system-services/
dbus_DATA=com.ridgerun.ipiped.service

dbusconfdir=@DBUS_SYSCONFIG_DIR@/dbus-1/system.d/
dbusconf_DATA=com.ridgerun.ipiped.conf

ipipeconfdir= $(datadir)/ipiped/
ipipeconf_DATA=config/dm365_mt9p031_config config/dm365_mt9p011_config

sysconf_DATA=config/ipiped.conf

EXTRA_DIST = ipiped-1.1.pc.in com.ridgerun.ipiped.service.in com.ridgerun.ipiped.conf config

