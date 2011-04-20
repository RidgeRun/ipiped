using GLib;
[DBus (name = "com.ridgerun.mt9p031Interface")]
public interface Imt9p031: Object{
    public abstract int set_sensor_gain(double r_gain, double g_gain, 
        double b_gain) throws IOError;
    public abstract int get_sensor_gain() throws IOError;
    public abstract int sensor_flip_vertically(string state) throws IOError;
    public abstract int sensor_flip_horizontally(string state) throws IOError;
    public abstract int get_exposure_time() throws IOError;
    public abstract int set_exposure_time(int _exp_time) throws IOError;
}

public class cli_mt9p031 : AbstcCliRegister{
    static bool _debug = false;
    public Imt9p031 sensor;
    /* Include the command's data in the array*/
    public cli_mt9p031(bool debug){
        _debug = debug;
    }

    public int cmd_set_sensor_gain(string[]? args) {
        if (args[1] == null || args[2] == null || args[3] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        double red = double.parse(args[1]);
        double green = double.parse(args[2]);
        double blue = double.parse(args[3]);

        try {
            int ret = sensor.set_sensor_gain(red, green, blue);
            if (ret != 0) {
                stderr.printf("Error:\n Failed to set sensor gain\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set sensor gain\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }
 
    /** 
     * Cmd Get sensor gain
     * Use the get_sensor_gain function to obtain the RGB sensor gains 
     * and print them
     */
    public int cmd_get_sensor_gain( string[]? args) {
 
       try {
            int ret = sensor.get_sensor_gain();
            if (ret != 0) {
                stderr.printf("Error:\n Failed to get sensor gain\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Get sensor gain\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }
  
    public int cmd_flip_vertically( string[]? args ){
        if (args[1] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }
        try {
            int ret = sensor.sensor_flip_vertically(args[1]);
            if (ret != 0) {
                stderr.printf("Error:\n Failed to set vertical flip\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Flip vertical\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    public int cmd_flip_horizontally( string[]? args){
        if (args[1] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }
        try {
            int ret = sensor.sensor_flip_horizontally(args[1]);
            if (ret != 0) {
                stderr.printf("Error:\n Failed to set horizontal flip\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Flip horizontal\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    public int cmd_set_exposure_time( string[]? args) {

        if (args[1] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        int time = int.parse(args[1]);

        try {
            int ret = sensor.set_exposure_time(time);
            if (ret != 0) {
                stderr.printf("Error:\n Failed to set exposure time\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set exposure time\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    public int cmd_get_exposure_time( string[]? args) {
        try {
            int ret = sensor.get_exposure_time();
            if (ret != 0) {
                stderr.printf("Error:\n Failed to set exposure time\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Get exposure time\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    /* Initialize the Command Array. */
    public override void registration(IpipeCli cli) throws IOError{
        cli.cmd.new_command("flip-vertical", cmd_flip_vertically, "fip-vertical <state>",
            "Flips the image vertically(on the sensor)", "state indicates the "
             + "status of the vertical flip.\n\t The options are \"ON\" or "
             + " \"OFF\"");
        cli.cmd.new_command("flip-horizontal", cmd_flip_horizontally, "flip-horizontal" 
            + "<state>", "Flips the image horizontally (on the sensor)",
            "state indicates the status of the horizontal flip." 
            + "\n\t The options are \"ON\" or \"OFF\"");
        cli.cmd.new_command("set-exposure", cmd_set_exposure_time, "set-exposure <T[us]>",
            "Sets the effective shutter time  of the sensor for the light " 
            + "integration", "T: effective shutter time in micro-seconds");
        cli.cmd.new_command("get-exposure", cmd_get_exposure_time, "get-exposure",
            "Gets the exposure time of the sensor in us","");
        cli.cmd.new_command("set-sensor-gain", cmd_set_sensor_gain, 
            "set-sensor-gain <R> <G> <B>",
            "Sets red(R), green(G) and blue(B) gain directly on the sensor",
            "\n\tEach gain component can range from 0 to 128 in steps of "
            + "\n\t\t0.125 if gain between 1 and 4\n\t\t0.250 if gain " 
            +"between 4.25 and 8\n\t\t1.000 if gain betwewn 8 and 128" 
            +"\n\tR: red gain\n\tG: green gain\n\tB: blue gain\n");
        cli.cmd.new_command("get-sensor-gain", cmd_get_sensor_gain, "get-sensor-gain",
            "Gets sensor red(R), green(G) and blue(B)", ""); 
        sensor = Bus.get_proxy_sync (BusType.SYSTEM, "com.ridgerun.ipiped",
                                                        "/com/ridgerun/ipiped/ipipe");
        return;
    }
}
