/**
 * ipiped/src/ipipe-client.vala
 *
 * Command line utility for sending D-Bus messages to Ipipe daemon with interactive support.
 *
 * Copyright (c) 2010, RidgeRun
 * All rights reserved.
 *
*/

using Posix, GLib;
[DBus (name = "com.ridgerun.ipiped.IpipeInterface")]
public interface ICliIpipe: Object{
    public abstract void enable_debug(bool enable) throws IOError;
    public abstract bool ping() throws IOError;
    public abstract string get_video_processor() throws IOError;
    public abstract string get_sensor() throws IOError;
    public abstract int init_aew(int time, int width, int height, 
        int segment_factor) throws IOError;
    public abstract bool get_aew_status(out bool awb_config, out bool ae_config,
        out int time, out int width, out int height, out int segment_factor) 
        throws IOError;
    public abstract int set_auto_exposure_configuration(string ae, string meter, 
        int rect_percentage, int xrect, int yrect) throws IOError;
    public abstract int get_auto_exposure_configuration(out string ae, 
        out string meter, out int rect_percentage, out int xrect, 
        out int yrect) throws IOError;
    public abstract int set_auto_white_balance_configuration(string wb, 
        string g) throws IOError;
    public abstract int get_auto_white_balance_configuration(out string wb, 
        out string g) throws IOError;
    public abstract void close_aew() throws IOError;
    public abstract int get_ae_rectangle_coordinates(out uint right, 
        out uint left, out uint top, out uint bottom) throws IOError;
}

public class IpipeCli: GLib.Object {
    /*Private Variables */
    private bool cli_enable = true;
    public CommandManager cmd = new CommandManager();
    ICliIpipe ipipe;
    AbstcCliRegister video_processor_i;
    AbstcCliRegister sensor_i;
    /*Variables to save option args */
    static string _cmd_name;
    static bool _debug = false;
    [CCode(array_length = false, array_null_terminated = true)]
    static string[] _remaining_args;
    /**
     * Application command line options
     */
    const OptionEntry[] options = {

        {"command-help", 'h', 0, OptionArg.STRING, ref _cmd_name,
            "Display possible commands for this application.\n\t\t\t "
             + "\n\t\t\t Usage:-h <cmd_name>", null},

        {"debug", 'd', 0, OptionArg.INT, ref _debug,
            "Flag to enable debug information on ipipe-client."
             + "\n\t\t\t Usage:-d <1>", null},

        {"", '\0', 0, OptionArg.FILENAME_ARRAY, ref _remaining_args,
            null, N_("[COMMANDS...]")},

        {null}
    };

    /**
     * Constructor
     */
    public IpipeCli() throws IOError{
        ipipe = Bus.get_proxy_sync (BusType.SYSTEM, "com.ridgerun.ipiped",
                                                      "/com/ridgerun/ipiped/ipipe");
    }
    /**
     *Callback functions for the receiving signals
     */ 
    public void Error_cb() {
        Posix.stdout.printf("Error signal received\n");
    }

    /**
     * Console Commands Functions
     */
    private int cli_enable_debug(string[]? args) {
        bool debug_enable;
        if (args[1] == null) {
            Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }
        if (args[1] == "true") {
            debug_enable = true;
            _debug = true;
        }else if (args[1] == "false"){
            debug_enable = false;
            _debug = false;
        }else {
            Posix.stderr.printf("Invalid argument value\n");
            return -1;
        }
        try {
            ipipe.enable_debug(debug_enable);
        }
        catch(IOError e) {
            Posix.stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
        return 0;
    }

    private int cli_ping(string[]? args) {

        bool ret;
        try {
            ret = ipipe.ping();
            if (!ret)
                return -1;
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to reach ipiped-daemon!\n");
            return -1;
        }

        Posix.stdout.printf("pong\n");
        return 0;
    }

    private int cli_shell(string[]? args) {
        string[]command;

        /*Join shellcommand and split it using quote
           character as divider */
        command = string.joinv(" ", args).split("\"", -1);

        try {
            GLib.Process.spawn_command_line_sync(command[1]);
            return 0;
        }
        catch(GLib.SpawnError e) {
            Posix.stderr.printf("Fail to execute command:%s", e.message);
        }
        return -1;
    }

    private int cli_get_video_processor(string[]? args) {
        string ret;
        try {
            ret = ipipe.get_video_processor();
            if (ret==null)
                return -1;
            else
                Posix.stdout.printf("Video processor: %s\n", ret);
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get video processor\n");
            return -1;
        }
        return 0;
    }

    private int cli_get_sensor(string[]? args) {

        string ret;
        try {
            ret = ipipe.get_sensor();
            if (ret==null)
                return -1;
            else
                Posix.stdout.printf("Sensor: %s\n", ret);
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get video processor\n");
            return -1;
        }
        return 0;
    }

    private int cli_run_config_script(string[]? args) {
        string dir ="/usr/share/ipiped/";
        string data, filename;
        if (args[1] == null) {
            Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }
        filename = dir.concat(args[1]);
        int i;
       // A reference to the file
       FILE file = FILE.open(filename, "r");
        if ( file != null ){
            char line [128]; /*maximum line size */
            while ( (data =file.gets(line)) != null ) /* read a line */
            {
                var s= data.split(" ", 10);
                for (i = 1; i < s.length; i++)
                    s[i] = s[i].strip();
                cmd.execute_cmd(/*ipipe,*/ s);
            }
        } else {
            Posix.stderr.printf("Configuration file %s doesn't exist\n", filename);
            return -1;
        }
        return 0;
    }

    private int cli_ini_aew(string[]? args) {

    #if (RRAEW)
        int i =0;
        const uint min_args = 3, max_args = 4;
        int wait_time, width, height, segment_factor = 100;
        /*Get the number of input arguments*/
        while (args[i + 1] != null){
            i++;
        }

        if ( i < min_args){
            Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        if ( i > max_args){
            Posix.stdout.printf("Error:\nMore arguments than required.Execute:'help <command>'\n");
            return -1;
        }

        wait_time = int.parse(args[1]);
        width = int.parse(args[2]);
        height = int.parse(args[3]);
        if (i == max_args) {
            segment_factor = int.parse(args[4]);
        }

        try {
            int ret = ipipe.init_aew(wait_time, width, height, segment_factor);
            if (ret < 0) {
                Posix.stderr.printf("Error:\n Failed to initialize aew\n");
                return -1;
            } else {
                if (_debug)
                    Posix.stdout.printf("Ok.\n");
                return 0;
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    #else
        Posix.stdout.printf("\nAEW is not supported because ipipe was compiled without librraew\n\n");
        return 0;
    #endif
    }

#if (RRAEW)
    private int cli_get_aew(string[]? args) {
        bool awb_config, ae_config;
        int time, width, height, segment_factor;
        bool running;
        try {
            running = ipipe.get_aew_status(out awb_config, out ae_config, 
                out time, out width, out height, out segment_factor);

            Posix.stdout.printf("\033[1mAEW Configuration\033[m\n");
            if (awb_config){
                Posix.stdout.printf("-> Auto white balance is configured\n");
            } else {
                Posix.stdout.printf("-> Auto white balance is not configured\n");
            }

            if (ae_config){
                Posix.stdout.printf("-> Auto exposure is configured\n");
            } else {
                Posix.stdout.printf("-> Auto exposure is not configured\n");
            }

            if (!running){
                Posix.stdout.printf("-> aew is stopped\n");
            } else {
                Posix.stdout.printf("-> Time between iterations: %i us\n", time);
                Posix.stdout.printf("-> Image width: %i\n", width);
                Posix.stdout.printf("-> Image height: %i\n", height);
                Posix.stdout.printf("-> Segmentation: %i%%\n", segment_factor);
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get video processor\n");
            return -1;
        }
        return 0;
    }
    private int cli_get_awb(string[]? args) {
        string wb, g;
        int ret;
        try {
            ret = ipipe.get_auto_white_balance_configuration(out wb, out g);
            if (ret == -1 ){
                Posix.stdout.printf("-> Auto white balance is not configured\n");
            } else {
                Posix.stdout.printf("\033[1mAuto White Balance Configuration\033[m\n");
                Posix.stdout.printf("-> Algorithm: %s\n", wb);
                Posix.stdout.printf("-> Gain type: %s\n", g);
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get auto white balance" + 
                " configuration\n");
            return -1;
        }
        return 0;
    }
    private int cli_get_ae(string[]? args) {
        string ae, meter;
        int rect_percentage, xrect, yrect;
        int ret;
        try {
            ret = ipipe.get_auto_exposure_configuration(out ae, out meter, 
            out rect_percentage, out xrect, out yrect);
            if (ret == -1 ){
                Posix.stdout.printf("-> Auto exposure is not configured\n");
            } else {
                Posix.stdout.printf("\033[1mAuto Exposure Configuration\033[m\n");
                Posix.stdout.printf("-> Algorithm: %s\n", ae);
                Posix.stdout.printf("-> Metering system: %s\n", meter);
                Posix.stdout.printf("-> Rectangle area percentage: %i%%\n", rect_percentage);
                Posix.stdout.printf("-> Rectangle center point: (%i, %i)\n", xrect, yrect);
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get auto exposure configuration\n");
            return -1;
        }
        return 0;
    }

    private int cli_get_rect(string[]? args) {
        uint right, left, top, bottom;
        int ret;
        try {
            ret = ipipe.get_ae_rectangle_coordinates(out right, out left,
                out top, out bottom);
            if (ret == -1 ){
                Posix.stdout.printf(" Failed to get rectangle. The aew isn't\n" 
                    + " initialized or the selected auto exposure metering\n" 
                    + " system doesn't use the rectangle of interest\n");
            } else {
                Posix.stdout.printf("- top-left point: (%u, %u)\n", left, top);
                Posix.stdout.printf("- botton-right point: (%u, %u)\n", right, bottom);
                Posix.stdout.printf("- width: %u\n", right - left);
                Posix.stdout.printf("- height: %u\n", bottom - top);
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Error:\nFailed to get rectangle coordinates\n");
            return -1;
        }
        return 0;
    }

    private int cli_set_awb(string[]? args) {

        int i = 0;
        const uint min_args = 1, max_args = 2;
        string gain;
        /*Get the number of input arguments*/
        while (args[i + 1] != null){
            i++;
        }

        if ( i < min_args){
            Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        if ( i > max_args){
            Posix.stdout.printf("Error:\nMore arguments than required.Execute:'help <command>'\n");
            return -1;
        }

        if (args[2] == null)
            gain = "default";
        else 
            gain = args[2];

        try {
            int ret = ipipe.set_auto_white_balance_configuration(args[1], gain);
            if (ret < 0) {
                Posix.stderr.printf("Error:\n Failed to configure auto white balance\n");
                return -1;
            } else {
                if (_debug)
                    Posix.stdout.printf("Ok.\n");
                return 0;
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }
    
    private int cli_set_ae(string[]? args) {

        int i = 0;
        const uint min_args = 2, max_args = 5;
        int rect_percentage = 40, xrect = -1, yrect = -1;
        /*Get the number of input arguments*/
        while (args[i + 1] != null){
            i++;
        }

        if ( i < min_args){
            Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        if ( i > max_args){
            Posix.stdout.printf("Error:\nMore arguments than required. Execute:'help <command>'\n");
            return -1;
        }
        if (args[3] != null){
            rect_percentage = int.parse(args[3]);

            if (i == max_args){
                xrect = int.parse(args[4]);
                yrect = int.parse(args[5]);
            }
        }
        try {
            int ret = ipipe.set_auto_exposure_configuration(args[1], args[2], 
                rect_percentage, xrect, yrect);
            if (ret < 0) {
                Posix.stderr.printf("Error:\n Failed to configure auto exposure\n");
                return -1;
            } else {
                if (_debug)
                    Posix.stdout.printf("Ok.\n");
                return 0;
            }
        }
        catch(Error e) {
            Posix.stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }
#endif
    private int cli_stop_aew(string[]? args) {
#if (RRAEW)
        try {
            ipipe.close_aew();
            if (_debug)
                Posix.stdout.printf("Ok.\n");
            return 0;
        }
        catch(Error e) {
            Posix.stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
#else
        Posix.stdout.printf("\nAEW is not supported because ipipe was compiled without librraew\n\n");
        return 0;
#endif
    }

    private int cli_exit(string[]? args) {
        cli_enable = false;
        if (_debug)
            Posix.stdout.printf("Ok.\n");
        return 0;
    }

    /* Initialize the Command Array. */
    private void initialize_cmd_array() {
        cmd.new_command("help", cmd.command_help, "\033[1mhelp\033[m [command]",
            "Displays the help text for all the possible commands or a specific "
            + "command", "", ""); 
        cmd.new_command("set-debug", cli_enable_debug, "\033[1mset-debug\033[m"
            +" <true/false>", "Enable/Disable debug messages","",
            "\n\ttrue: enables debug, \n\tfalse: disables debug");
        cmd.new_command("shell", cli_shell, "\033[1mshell\033[m \"shell_cmd\"",
            "Execute a shell command(shell_cmd) using interactive console","","");
        cmd.new_command("ping", cli_ping, "\033[1mping\033[m", 
            "Show if ipipe-daemon is alive", "", "");
        cmd.new_command("quit", cli_exit, "\033[1mquit\033[m", 
            "Quit from the interactive console", "", "");
        cmd.new_command("exit", cli_exit, "\033[1mexit\033[m", 
            "Exit from the interactive console", "", "");
        cmd.new_command("get-video-processor", cli_get_video_processor, 
            "\033[1mget-video-processor\033[m", "Show the video processor that" 
            + " is being used", "", "");
        cmd.new_command("get-sensor", cli_get_sensor, "\033[1mget-sensor\033[m", 
            "Show the sensor that is being used","", "");
        cmd.new_command("run-config-script", cli_run_config_script, 
            "\033[1mrun-config-script script\033[m", 
            "Execute a group of ipipe-client commands", "",
            "\n\tscript: the name of the script");
#if (RRAEW)
        cmd.new_command("set-awb", cli_set_awb, "\033[1m set-awb \033[m algorithm [gain]", 
            "Set the configuration of auto white balance(awb)", 
            "\tYou can configure the auto white balance whenever you want but" 
            + "\n\tthe changes will be applied the next time that you run init-aew."
            + "\n\tIf awb isn't configured, none auto-white balance will be applied" 
            + "\n\tto the video.",
            "\n\talgorithm: white balance algorithm, the options are:"
                + "\n\t\tgray-world -for gray world algorithm" 
                + "\n\t\twhite-patch -for retinex algorithm"
                + "\n\t\twhite-patch2 -for variant of retinex algorithm"
                + "\n\t\tnone -for none" 
            + "\n\tgain: gain type, the options are: " 
                + "\n\t\tsensor -to use the sensor gain "  
                + "\n\t\tdigital -to use the digital" );
        cmd.new_command("set-ae", cli_set_ae, "\033[1m set-ae \033[m algorithm metering"
            + " [rect_percentage] [xrect] [yrect] ", 
            "Set the configuration of auto exposure", 
            "\tYou can configure the auto exposure whenever you want but " 
            + "\n\tthe changes will be applied the next time that you run init-aew."
            + "\n\tIf it is not configured, none auto-exposure will be applied to " 
            + "\n\tthe video",  
            "\n\talgorithm: auto exposure algorithm, the options are" 
                + "\n\t\telectronic-centric -for electronic centric"
                + "\n\t\tnone -for none"
            + "\n\tmetering: exposure metering method, the options are:" 
                + "\n\t\tpartial -for partial metering that take into account " 
                + "\n\t\t\tthe light information of a portion of the frame"  
                + "\n\t\t\t(rectangle of interest) and the rest of the frame"  
                + "\n\t\t\tis ignored. The size  of the rectangle of interest "  
                + "\n\t\t\tdepends on the rect_percentage parameter and its " 
                + "\n\t\t\tposition depends on the rect coordinates (xrect, yrect)"
                + "\n\t\tweighted -for rectangle weighted metering that take "  
                + "\n\t\t\tinto account the light information coming from the "  
                + "\n\t\t\tentire frame with emphasis placed on the rectangle of "
                + "\n\t\t\tinterest defined by rect_percentage, xrect and yrect" 
                + "\n\t\taverage -for average metering that take into account the light " 
                + "\n\t\t\tinformation from the entire frame without weighting"  
                + "\n\t\tsegmented -for segmented metering that divides the frame "  
                + "\n\t\t\ton 6 pieces and weighting them to avoid backlighting."
                + "\n\t\t\tThe center piece's size is determined by the rect_percentage" 
            + "\n\trect_percentage: defines the percentage of the image width" 
                + "\n\t\tand height to be used as the center size. Default: 40"
            + "\n\txrect: x coordinate for the center point of the rectangle " 
                + "\n\t\tof interest. If you want to locate the rectangle of "
                + "\n\t\tinterest in the image's center you have to set " 
                + "\n\t\txrect=yrect=-1. Default: -1"
            + "\n\tyrect: y coordinate for the center point of the rectangle "
                +"\n\t\tof interest. Default: -1");
#endif
        cmd.new_command("init-aew", cli_ini_aew, "\033[1m init-aew \033[m  time<us>" 
            + " width height segmentation", "Initialize aew algorithms", 
            "\tThis command configures general aspects for the aew functionality" 
            + "\n\tand starts the automatic adjustments iterations. Auto white " 
            + "\n\tbalance and auto exposure configurations must be done before " 
            + "\n\tyou execute this command. If not the aew will run but no adjusment"
            + " \n\twill be made","\n\ttime: wait time in us, specifies the time between " 
            + "\n\t\talgorithm adjustments, max value=1s=1000000us"
            + "\n\twidth: captured video/image horizontal size"
            + "\n\theight: captured video/image vertical size" 
            + "\n\tsegmentation: frame segmentation factor, each frame is segmented into " 
                + "\n\t\tregions, this factor represents the percentage of the "  
                + "\n\t\tmaximum number of possible regions" );
        cmd.new_command("stop-aew", cli_stop_aew, "\033[1mstop-aew\033[m", 
            "End aew algorithm", 
            "\tThis command stops the automatic adjustments. You need to run " 
            + "\n\tinit-aew to restart them but you don't need to reconfigure the" 
            + "\n\tauto white balance and auto exposure. The last configuration is " 
            + "\n\tsaved", "");
#if (RRAEW)
        cmd.new_command("get-awb-config", cli_get_awb, "\033[1mget-awb-config\033[m", 
            "Get auto white balance current configuration","", "");
        cmd.new_command("get-ae-config", cli_get_ae, "\033[1mget-ae-config\033[m", 
            "Get auto exposure current configuration","", "");
        cmd.new_command("get-aew-config", cli_get_aew, "\033[1mget-aew-config\033[m", 
            "Get aew current status and configuration", "","");
        cmd.new_command("get-rectangle", cli_get_rect, "\033[1mget-rectangle\033[m", 
            "Get current rectangle coordinates", "","");
#endif
    }

    /**
     *Parse entry-options or flags:
     *_cmd_name:   Command name in which 'help' description
     *           will be display
     *
     *_debug:               flag to enable debug information
     * 
     *_remaining_args:  command to be executed remains here,
     *                  if there is no remaining args interactive
     *                  console is enable.
     */
    public bool parse_options(string[]args) {

        /*Clean up global reference variables */
        _cmd_name = null;
        _debug = false;
        _remaining_args = null;

        /*Parsing options */
        var opt =
            new OptionContext("(For Commands HELP: 'ipipe-client help')");
        opt.set_help_enabled(true);
        opt.add_main_entries(options, null);

        try {
            opt.parse(ref args);
            if (_cmd_name != null) {
                cli_enable = false;
                cmd.command_help(/*ipipe,*/ {
                    "help", _cmd_name, "\0"}
                );
            }
        }
        catch(GLib.OptionError e) {
            Posix.stderr.
                printf("OptionError failure: %s. See 'ipipe-client --help'\n",
                e.message);
            return false;
        }
        return true;
    }

    /**
     *Interactive Console management
     */
    public bool parse_cmd(string[]rem_args) throws IOError {

        string[] args;
        if (rem_args != null) {
            cmd.execute_cmd(/*ipipe, */rem_args);
            cli_enable = false;
        }

        string home = GLib.Environment.get_variable("HOME");
        Readline.History.read(home + "/.ipipe-client_history");

        while (!GLib.stdin.eof()) {
            /*Exit from cli */
            if (!cli_enable)
                break;
            /*Get the command from the stdin */
            var cmd_line = Readline.readline("ipipe-client$ ");

            /*Removes leading and trailing whitespace */
            cmd_line = cmd_line.strip();
            if ((cmd_line != null) && (cmd_line.length > 1)){
                /*Saving command on history */
                Readline.History.add(cmd_line);
                /*Splits string into an array */
                args = cmd_line.split(" ", -1);

                /*Execute the command */
                if (args[0] != null && cmd_line[0] != '#')
                    cmd.execute_cmd(args);
            }
        }
        Readline.History.write(home + "/.ipipe-client_history");
        return true;
    }

    public bool parse_config(IpipeCli cli) throws IOError{
        string sensor = ipipe.get_sensor();
        string video_processor = ipipe.get_video_processor();
        if (video_processor == "dm365"){
            var video_processor_obj = new cli_dm365ipipe(_debug);
            video_processor_obj.registration(cli);
            video_processor_i = video_processor_obj;
        } else {
            Posix.stderr.printf("Video processor doesn't match with available platforms \n"); 
            return false;   
        }

        if (sensor == "mt9p031"){
            var sensor_obj = new cli_mt9p031(_debug);
            sensor_obj.registration(cli);
            sensor_i = sensor_obj;
        } else {
            Posix.stderr.printf("Sensor support doesn't exist \n");
            return false;
        }
        return true;
    }
    static int main(string[]args) {
        IpipeCli cli;

        try {

            cli = new IpipeCli();
            cli.initialize_cmd_array();
            /*Parse entry options or flags and
               fill the reference variables */
            if (!cli.parse_options(args))
                return -1;

            if (!cli.parse_config(cli))
                return -1;

            /*Parse commands */
            if (!cli.parse_cmd(_remaining_args))
                return -1;

        }
        catch(IOError e) {
            Posix.stderr.printf("ipipe-client> DBus failure: %s\n", e.message);
            return 1;
        }
        return 0;
    }
}
