AC_INIT([ipiped],[1.1],[support@ridgerun.com])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIR([m4])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile src/Makefile])
AC_CONFIG_FILES(ipiped-1.0.pc:ipiped-1.0.pc.in)
AC_CONFIG_FILES(com.ridgerun.ipiped.service:com.ridgerun.ipiped.service.in)

AM_PROG_VALAC([0.7.6])

dnl Check for pkgconfig first
AC_CHECK_PROG(HAVE_PKGCONFIG, pkg-config, yes, no)
dnl Give error and exit if we don't have pkgconfig
if test "x$HAVE_PKGCONFIG" = "xno"; then
  AC_MSG_ERROR(you need to have pkgconfig installed !)
fi


dnl Now we're ready to ask for gthread
PKG_CHECK_MODULES(GTHREAD, gthread-2.0, HAVE_GTHREAD=yes, HAVE_GTHREAD=no)
dnl Give error and exit if we don't have gthread
if test "x$HAVE_GTHREAD" = "xno"; then
  AC_MSG_ERROR([you need gthread development packages installed!])
fi
dnl append GTHREAD_ERROR cflags to GTHREAD_CFLAGS
GTHREAD_CFLAGS="$GTHREAD_CFLAGS $GTHREAD_ERROR"
dnl make GTHREAD_CFLAGS and GTHREAD_LIBS available
AC_SUBST(GTHREAD_CFLAGS)
AC_SUBST(GTHREAD_LIBS)


dnl Now we're ready to ask for dbus
PKG_CHECK_MODULES(DBUS, dbus-1, HAVE_DBUS=yes, HAVE_DBUS=no)
dnl Give error and exit if we don't have dbus
if test "x$HAVE_DBUS" = "xno"; then
  AC_MSG_ERROR([you need dbus development packages installed!])
fi
_PKG_CONFIG([DBUS_SYSCONFIG_DIR],[variable=sysconfdir],[dbus-1])
DBUS_SYSCONFIG_DIR=$pkg_cv_DBUS_SYSCONFIG_DIR
AC_SUBST(DBUS_SYSCONFIG_DIR)

dnl Now we're ready to ask for gio-2.0
PKG_CHECK_MODULES(GIO, gio-2.0, HAVE_GIO=yes, HAVE_GIO=no)
#if test "x$HAVE_GIO = "xno"; then
#  AC_MSG_ERROR([you need gio-2.0 development packages installed !])
#fi
dnl make GIO_CFLAGS and GIO_LIBS available
AC_SUBST(GIO_CFLAGS)
AC_SUBST(GIO_LIBS)


dnl Now we're ready to ask for librraew
PKG_CHECK_MODULES(LIBRRAEW, librraew >= 1.0, HAVE_LIBRRAEW=yes, HAVE_LIBRRAEW=no)
LIBRRAEW_VALAFLAGS=`pkg-config --variable=valaflags librraew`

dnl make the FLAGS and LIBS available
AM_CONDITIONAL([USE_LIBRRAEW], [test x$HAVE_LIBRRAEW = xyes])
AC_SUBST(LIBRRAEW_CFLAGS)
AC_SUBST(LIBRRAEW_LIBS)
AC_SUBST(LIBRRAEW_VALAFLAGS)

if test -z "$VAPIDIR"; then
    VAPIDIR=/usr/share/vala/vapi
fi
AC_ARG_VAR([VAPIDIR], [path for the vala bindings])
AC_ARG_WITH(vapidir,
    [AS_HELP_STRING([--with-vapidir=<path>],
        [Set the path for the vapidir])],
    [AC_MSG_NOTICE([Setting the vapidir "$withval"])
     AC_SUBST([VAPIDIR],[$withval])
    ]
)

AC_OUTPUT
