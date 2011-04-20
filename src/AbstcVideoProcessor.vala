using V4l2;
#if (RRAEW)
using rraew;
#endif

public abstract class AbstcVideoProcessor : GLib.Object {
    /** Flag to enable/disable debug information */
    public static bool debug = false;
    /** Previewer file descriptor */
    public int previewer_fd;
    /** AEW engine file descriptor */
    public int aew_fd;
    /** Flags that tell if the previewer file descriptor is created 
     * for aew library(owned) or is given by the user*/
    public char owner_previewer_fd;
    /** Flags that tell if the aew file descriptor is created 
     * for aew library(owned) or is given by the user*/
    public char owner_aew_fd;

#if (RRAEW)
    /* Methods that required the aew library*/
    public abstract bool get_video_processor_data(Interface *interf);
#endif
}
