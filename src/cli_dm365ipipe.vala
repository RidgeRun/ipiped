using GLib;

[DBus (name = "com.ridgerun.dm365ipipeInterface")]
public interface Idm365ipipe: Object{
    public abstract bool set_previewer_mode(string mode_s) throws IOError;
    public abstract bool set_color_pattern(string colorptn) throws IOError;
    public abstract bool set_digital_gain(double red_gain, double green_gain, 
        double blue_gain) throws IOError;
    public abstract bool get_digital_gain(out double _red_gain,
        out double blue_gain, out double green_gain) throws IOError;
    public abstract bool set_luminance_adj(int bright, double contr) throws IOError;
    public abstract bool get_luminance_adj(out int bright, out double contr) throws IOError;
    public abstract bool config_bsc(uint inwidth, uint inheight) throws IOError;
}

public class cli_dm365ipipe : AbstcCliRegister{
    static bool _debug = false;
    public Idm365ipipe ipipe;
    public cli_dm365ipipe(bool debug) throws IOError{
        _debug = debug;
    }

    private int cmd_set_previewer_mode(string[]? args) {
        if (args[1] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        try {
            if (!ipipe.set_previewer_mode(args[1])) {
                stderr.printf("Error:\n Failed to configure previewer\n");
                return -1;
            } else {
                if (_debug){
                    stdout.printf("Ipipe Previewer has been configured\n");
                    stdout.printf("Ok.\n");
                }
                return 0;
            }

        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }

    }

    private int cmd_set_digital_gain(string[]? args) {

        if (args[1] == null || args[2] == null || args[3] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        double red = double.parse(args[1]);
        double green = double.parse(args[2]);
        double blue = double.parse(args[3]);

        try {
            if (!ipipe.set_digital_gain(red, green, blue)) {
                stderr.printf("Error:\n Failed to set the digital gain\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set digital gain\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }

    }

    private int cmd_get_digital_gain(string[]? args) {
        try {
            double red_gain = 0, green_gain = 0, blue_gain = 0;

            if (!ipipe.get_digital_gain(out red_gain, 
                    out green_gain, out blue_gain)) {
                stderr.printf("Error:\n Failed to get the digital gain\n");
                return -1;
            } else {
                Posix.stdout.printf("Digital gain:  R=%f  G=%f  B=%f\n",
                    red_gain,green_gain,blue_gain);
                if (_debug)
                    stdout.printf("Ok.Get digital gain\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }

    }

    private int cmd_set_lum_adj(string[]? args) {

        if (args[1] == null || args[2] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }

        int brightness = int.parse(args[1]);
        double contrast = double.parse(args[2]);

        try {
            if (!ipipe.set_luminance_adj(brightness, contrast)) {
                stderr.
                    printf("Error:\n Failed to set the luminant adjusment\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set luminance adjusment\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    private int cmd_get_lum_adj(string[]? args) {
       int brightness;
       double contrast;

       try {
            if (!ipipe.get_luminance_adj(out brightness, out contrast)) {
                stderr.
                    printf("Error:\n Failed to get the luminant adjusment\n");
                return -1;
            } else {
                Posix.stdout.printf("Luminance adjustment: Brightness=%d," +
                   " Contrast=%f\n", brightness, contrast);
                if (_debug)
                    stdout.printf("Ok.Get luminance adjusment\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    private int cmd_set_color_pattern(string[]? args){
         if (args[1] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help <command>'\n");
            return -1;
        }
        try {
            if (!ipipe.set_color_pattern(args[1])) {
                stderr.printf("Error:\n Failed to set color_pattern\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set bayer pattern\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
    }

    private int cmd_config_video_stabilization(string[]? args) {
#if BSC_ENABLE
        if (args[1] == null || args[2] == null) {
            stdout.printf("Error:\nMissing argument.Execute:'help config_video_stabilization'\n");
            return -1;
        }
        uint width = int.parse(args[1]);
        uint height = int.parse(args[2]);

        try {
            if (!ipipe.config_bsc(width, height)) {
                stderr.
                    printf("Error:\n Failed to config bsc\n");
                return -1;
            } else {
                if (_debug)
                    stdout.printf("Ok.Set bsc configuration\n");
                return 0;
            }
        }
        catch(Error e) {
            stderr.printf("Fail to execute command:%s\n", e.message);
            return -1;
        }
#else
        stdout.printf("Video stabilization not supported\n");
        return 0;
#endif
    }

    /* Initialize the Command Array. */
    public override void registration(IpipeCli cli) throws IOError{
        cli.cmd.new_command("set-previewer-mode", cmd_set_previewer_mode, 
            "\033[1mset_previewer_mode\033[m <cont/one-shot>", 
            "Configure previewer on continuous or one-shot mode", "", 
            "\n\tcont: sets previewer on continous mode" 
            + "\n\tone-shot: sets previewer on one shot mode");
        cli.cmd.new_command("set-bayer-pattern", cmd_set_color_pattern, 
            "\033[1mset-bayer-pattern\033[m ptrn","Sets R/Gr/Gb/B color pattern "
            + "to the previewer", "", "\n\tThe argument ptrn is the specific " 
            + "color pattern, \n\tthe options are: "
            + "\n\tGrRBGb: \n\t\tGr R\n\t\tB Gb\n\tBGbGrR: \n\t\tB Gb\n\t\tGr R"
            + "\n\tRGrGbB: \n\t\tR Gr\n\t\tGb B\n\tGbBRGr: \n\t\tGb B\n\t\tR Gr");
        cli.cmd.new_command("set-digital-gain", cmd_set_digital_gain, 
            "\033[1mset-digital-gain\033[m R G B", "Sets red (R), green (G)" 
            + " and blue gains (G) on the ipipe",   
            "\tEach gain component can range from 0 to 15.998 in steps of 1/512:", 
            "\n\tR: red gain\n\tG: green gain\n\tB: blue gain\n");
        cli.cmd.new_command("get-digital-gain", cmd_get_digital_gain, 
            "\033[1mget-digital-gain\033[m",
            "Returns the gain value for each color component(RGB)", "", "");
        cli.cmd.new_command("set-luminance", cmd_set_lum_adj, 
            "\033[1mset-luminance\033[m Br C",
            "Brightness(Br) and contrast(C) adjustment", "\tThis ajustment " 
            +"is applied to the luminance(Y) component, using the following "
            +"equation  Yctr_ brt = (Y x C) + Br ",
            "\n\tBr: brightness offset value for ipipe's brightness control,"
            +" it's an integer value that can range from 0 to 255"
            +"\n\tC: contrast multiplier coefficient, it's a float value" 
            +" that can range from 0 to 15.94");
        cli.cmd.new_command("get-luminance", cmd_get_lum_adj, 
            "\033[1mget-luminance\033[m",
            "Returns the value of the Brightness(Br) and contrast(C) adjustment",
            "", "");
        cli.cmd.new_command("config-vs", cmd_config_video_stabilization,
            "\033[1mconfig-vs\033[m width height",
            "Configures the boundary signal calculator module(bsc)"
            +" needed by the video stabilization",
            "\tThe video stabilization algorithm uses the vectors of sums"
            +"\n\tgiven by the bsc to calculate the compensation for"
            +"\n\tthe camera shaking."
            +"\n\tThe bsc is configured for an image of the given dimensions.",
            "\n\twidth: input image's width"
            +"\n\theight: input image's height");

        ipipe = Bus.get_proxy_sync (BusType.SYSTEM, "com.ridgerun.ipiped",
                                                        "/com/ridgerun/ipiped/ipipe");
        return;
    }
}


