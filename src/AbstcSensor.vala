#if (RRAEW)
using rraew;
#endif
public abstract class AbstcSensor : GLib.Object {
    /** Flag to enable/disable debug information */
    public static bool debug = false;
     /** Sensor file descriptor */
    public int capture_fd;
    /** Flags that tell if the capture file descriptor is created 
     * for aew library(owned) or is given by this class*/
    public char owner_capture_fd;
#if (RRAEW)
    /* Methods that required the aew library*/
    public abstract int get_sensor_data(RraewSensor *sensor);
#endif
}
