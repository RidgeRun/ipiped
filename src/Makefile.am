ACLOCAL_AMFLAGS = -I m4

bin_PROGRAMS = ipiped ipipe-client
ipiped_SOURCES = main.vala ipiped.vala ipiped-dm365.vala ipiped-mt9p031.vala AbstcVideoProcessor.vala AbstcSensor.vala
ipiped_VALAFLAGS = --thread --pkg v4l2 --pkg gio-2.0 --pkg posix  --pkg impprev --pkg dm365aew \
 --vapidir=@VAPIDIR@ --vapidir=../vapi @LIBRRAEW_VALAFLAGS@ 
ipiped_CFLAGS = @GTHREAD_CFLAGS@ @GIO_CFLAGS@ 
ipiped_LDADD = @GTHREAD_LIBS@ @GIO_LIBS@ 

ipipe_client_SOURCES = ipipe-client.vala command.vala cli_dm365ipipe.vala cli_mt9p031.vala AbstcCliRegister.vala 
ipipe_client_VALAFLAGS = --vapidir=@VAPIDIR@ --pkg glib-2.0 --pkg posix --pkg gio-2.0 --pkg readline -X -lreadline
ipipe_client_CFLAGS = @GIO_CFLAGS@ -DGETTEXT_PACKAGE=\"ipipe-client\"
ipipe_client_LDADD = @GIO_LIBS@ -lreadline -lncurses

if USE_LIBRRAEW
ipiped_LDADD += @LIBRRAEW_LIBS@ 
ipiped_CFLAGS += @LIBRRAEW_CFLAGS@
ipiped_VALAFLAGS += --define=RRAEW 
ipipe_client_VALAFLAGS += --define=RRAEW 
endif

#ipiped_VALAFLAGS += --define=BSC_ENABLE
#ipipe_client_VALAFLAGS += --define=BSC_ENABLE

interfaces_xml := com.ridgerun.ipiped.IpipeInterface.xml

EXTRA_DIST= $(interfaces_xml)

interfacedir=$(datadir)/dbus-1/interfaces/
interface_DATA= $(interfaces_xml)
