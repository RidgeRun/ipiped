/*
 * ipiped/src/main.vala
 *
 * Main function for Ipipe daemon - controlling IPIPE path on the Video Processing Subsystem
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
*/

/*Global Variable*/
using Posix, GLib;
void on_bus_aquired (DBusConnection conn) {
    string data, filename = "/usr/etc/ipiped.conf";
    string video_processor="", sensor="";
    AbstcVideoProcessor video_processor_abstract;
    AbstcSensor sensor_abstract;
    // A reference to the file
    FILE file = FILE.open(filename, "r");

    if ( file != null ){
        char line [128]; /*maximum line size */
        while ( (data =file.gets(line)) != null ) /* read a line */
        {
            var s= data.split("=", 2);
            if (s[0] == "processor"){
                video_processor = s[1].strip();
            }else if (s[0] == "sensor"){
                sensor = s[1].strip();
            }
        }
    } else {
        Posix.stderr.printf("Configuration file %s doesn't exist\n", filename);
        return;
    }

    try {

        if (video_processor == "dm365"){
            var ipiped_dm365 = new Ipiped_dm365();
            video_processor_abstract = ipiped_dm365;
            conn.register_object ("/com/ridgerun/ipiped/ipipe", ipiped_dm365);
        } else {
            Posix.stderr.printf("Video processor doesn't match with available platforms \n"); 
            return;
        }

        if (sensor == "mt9p031"){
            var ipiped_mt9p031 = new Ipiped_mt9p031();
            sensor_abstract=ipiped_mt9p031;
            conn.register_object ("/com/ridgerun/ipiped/ipipe", ipiped_mt9p031);
        } else {
            Posix.stderr.printf("Sensor support doesn't exist \n");
            return;
        }
        var ipipe = new Ipipe(sensor, video_processor, video_processor_abstract, sensor_abstract);
        /* Try to register service in session bus */
        conn.register_object ("/com/ridgerun/ipiped/ipipe", ipipe);
    } catch (IOError e) {
        GLib.stderr.printf ("Could not register service\n");
        GLib.stderr.printf ("Ipiped: Error: %s\n", e.message);
    }
}

public void main (string[]args) {

    Bus.own_name (BusType.SYSTEM, "com.ridgerun.ipiped", 
                BusNameOwnerFlags.NONE,
                on_bus_aquired,
                () => {},
                () => GLib.stderr.printf ("Ipiped: Failed to obtain primary ownership of " +
          "the service\nThis usually means there is another instance of " +
          " ipiped already running\n"));
    /* Creating a GLib main loop with a default context */
    new MainLoop ().run ();
}

