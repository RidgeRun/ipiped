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
    public abstract int init_aew(string wb, string ae, string g, string meter, 
        int time, int segment_factor, int width, int height, 
        int center_percentage) throws IOError;
    public abstract void close_aew() throws IOError;
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
        int i=0;
        // Check if there are missing args 
        while (i < 10) { 
            if (args[i] == null) {
                Posix.stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
                return -1;
            }
            i++;
        }
        int wait_time = int.parse(args[5]);
        int width = int.parse(args[7]);
        int height = int.parse(args[8]);
        int segment_factor = int.parse(args[6]);
        int center_percentage = int.parse(args[9]);
        try {
            int ret = ipipe.init_aew(args[1], args[2], args[3], args[4], wait_time, 
                segment_factor, width, height, center_percentage);
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
        cmd.new_command("help", cmd.command_help, "help [<command>]",
            "Displays the help text for all the possible commands or a specific "
            + "command", ""); 
        cmd.new_command("set-debug", cli_enable_debug, "set_debug <true/false>", 
            "Enable/Disable debug messages", "\n\ttrue: enables debug, " 
            + "\n\tfalse: disables debug" );
        cmd.new_command("init-aew", cli_ini_aew, "init-aew <WB> <AE> <G> <EM> " 
            + "<T[us]> <seg> <width> <height> <center_percentage>",
                "Initialize AEW algorithms",
            "\n\tWB: white balance algorithm, the options are:"
                + "\n\t\tG -for gray world algorithm" 
                + "\n\t\tW -for retinex algorithm"
                + "\n\t\tW2 -for variant of retinex algorithm"
                + "\n\t\tN -for none" 
            + "\n\tAE: auto exposure algorithm, the options are" 
                + "\n\t\tEC -for electronic centric"
                + "\n\t\tN -for none"  
            + "\n\tG: gain type, the options are: " 
                + "\n\t\tS -to use the sensor gain "  
                + "\n\t\tD -to use the digital" 
            + "\n\tEM: exposure metering method, the options are:" 
                + "\n\t\tP -for partial metering that take into account the light " 
                + "\n\t\tinformation of a portion in the center and the rest of " 
                + "\n\t\tthe frame is ignored. The size  of the center depends of "
                + "\n\t\tof the parameter center_percentage"
                + "\n\t\tC -for center weighted metering that take into account " 
                + "\n\t\tthe light information coming from the entire frame with " 
                + "\n\t\temphasis placed on the center area" 
                + "\n\t\tA -for average metering that take into account the light " 
                + "\n\t\tinformation from the entire frame without weighting"  
                + "\n\t\tSG -for segmented metering that divides the frame "  
                + "\n\t\ton 6 pieces and weighting them to avoid backlighting" 
            + "\n\tT: wait time in us, specifies the time between " 
            + "\n\t\talgorithm adjustments, max value=1s=1000000us"
            + "\n\tseg: frame segmentation factor, each frame is segmented into " 
                + "\n\t\tregions, this factor represents the percentage of the "  
                + "\n\t\tmaximum number of possible regions"
            + "\n\twidth: captured video/image horizontal size"
            + "\n\theight: captured video/image vertical size" 
            + "\n\tcenter_percentage: defines the percentage of the image width" 
            + "\n\t\tand height to be used as the center size");
        cmd.new_command("stop-aew", cli_stop_aew, "stop-aew", "End AEW algorithm", "");
        cmd.new_command("shell", cli_shell, "shell <\"shell_cmd\">",
            "Execute a shell command(shell_cmd) using interactive console", "");
        cmd.new_command("ping", cli_ping, "ping", "Show if ipipe-daemon is alive", "");
        cmd.new_command("quit", cli_exit, "quit", "Quit from the interactive console","");
        cmd.new_command("exit", cli_exit, "exit", "Exit from the interactive console","");
        cmd.new_command("get-video-processor", cli_get_video_processor, 
        "get-video-processor",  "Show the video processor that is being used","");
        cmd.new_command("get-sensor", cli_get_sensor, "get-sensor", "Show the sensor that is being used","");
        cmd.new_command("run-config-script", cli_run_config_script, 
        "run-config-script <script>", "Execute a group of ipipe-client commands", 
        "\n\t\tscript: is the name of script");
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

            if (cmd_line != null) {
                /*Saving command on history */
                Readline.History.add(cmd_line);

                /*Removes leading and trailing whitespace */
                cmd_line.strip();

                /*Splits string into an array */
                args = cmd_line.split(" ", -1);

                /*Execute the command */
                if (args[0] != null && cmd_line[0] != '#')
                    cmd.execute_cmd(/*ipipe,*/ args);
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
