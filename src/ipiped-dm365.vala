using Posix, ImpPrev;
#if (RRAEW)
using rraew;
#endif

[DBus (name = "com.ridgerun.dm365ipipeInterface")]
public class Ipiped_dm365 : AbstcVideoProcessor{

    /** Flag to indicate if the previewer is initialized*/
    private static bool initialized = false;

    /**
     * Create a new instance of a Ipipe daemon
     */
    public Ipiped_dm365(){
        /* Initialize private variables */
        initialized = false;
        this.debug = false;
        previewer_fd = -1;
        aew_fd = -1;
        owner_previewer_fd = 1;
        owner_aew_fd = 1;
    }

    /**
     * Configure the previewer mode with the default configuration
     * @param mode_s indicates if configure the previewer on continuos 
     * mode or single shot mode
     */
    public bool set_previewer_mode(string mode_s) throws IOError{
        ChannelConfig chan_config = ChannelConfig();
        uint mode;
        owner_previewer_fd = 0;

        if (mode_s == "cont"){
            mode = MODE_CONTINUOUS;
        } else if (mode_s == "one-shot"){
            mode = MODE_SINGLE_SHOT;
        } else {
            Posix.stderr.printf("Ipiped: Invalid previewer operation mode\n");
            return false;
        }

        if (initialized){
            if (debug)
                Posix.stderr.printf("Ipiped:Previewer is already configured\n");
            return true;
        }

        previewer_fd = Posix.open("/dev/davinci_previewer", Posix.O_RDWR);
        if (previewer_fd <0)
            return false;
        /*Set operation mode*/
        if (Posix.ioctl(previewer_fd , PREV_S_OPER_MODE, &mode)<0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Fail to set operation mode\n");
            return false;
        }
        /*Set default configuration*/
        chan_config.oper_mode = mode;
        chan_config.len = 0;
        chan_config.config = null;
        set_previewer_config(&chan_config);
        initialized = true;
        return true;
    }

    /* Set previewer config
     * Call the  ioctl PREV_S_CONFIG to configure the previewer 
     */
    private bool set_previewer_config(ChannelConfig* chan_config){
        if (Posix.ioctl(previewer_fd , PREV_S_CONFIG, chan_config)<0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Fail to set configuration\n");
            return false;
        }
        return true;
    }

    /* Get previewer config
     * Call the  ioctl PREV_G_CONFIG to get the actual previewer 
     * configuration
     */
    private bool get_previewer_config(ChannelConfig* chan_config){
        if (Posix.ioctl(previewer_fd , PREV_G_CONFIG, chan_config)<0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Fail to get configuration\n");
            return false;
        }
        return true;
    }

    /**
     * Set color pattern
     * Configure in the previewer the color pattern passed by the user
     * @param   colorptn is a string that represents the RGB color order*/
    public bool set_color_pattern(string colorptn) throws IOError{
        ChannelConfig chan_config = ChannelConfig();
        PreContinuosConfig prev_config= PreContinuosConfig();
        chan_config.oper_mode = MODE_CONTINUOUS;
        chan_config.len =(ushort)sizeof(PreContinuosConfig);
        chan_config.config = &prev_config;
        get_previewer_config(&chan_config);
        if (colorptn == "GrRBGb"){
            /**      Gr R
             *       B Gb
             */
            prev_config.input.colp_olop = IpipeColpat_t.GREEN_RED;
            prev_config.input.colp_olep = IpipeColpat_t.RED;
            prev_config.input.colp_elop = IpipeColpat_t.BLUE;
            prev_config.input.colp_elep = IpipeColpat_t.GREEN_BLUE;
        } else if (colorptn == "BGbGrR") {
            /**      B Gb
             *       Gr R
             */
            prev_config.input.colp_olop = IpipeColpat_t.BLUE;
            prev_config.input.colp_olep = IpipeColpat_t.GREEN_BLUE;
            prev_config.input.colp_elop = IpipeColpat_t.GREEN_RED;
            prev_config.input.colp_elep = IpipeColpat_t.RED;
        } else if (colorptn == "RGrGbB") {
            /**      R Gr
             *       Gb B
             */
            prev_config.input.colp_olop = IpipeColpat_t.RED;
            prev_config.input.colp_olep = IpipeColpat_t.GREEN_RED;
            prev_config.input.colp_elop = IpipeColpat_t.GREEN_BLUE;
            prev_config.input.colp_elep = IpipeColpat_t.BLUE;
        } else if (colorptn == "GbBRGr"){
            /**      Gb B
             *       R Gr
             */
            prev_config.input.colp_olop = IpipeColpat_t.GREEN_BLUE;
            prev_config.input.colp_olep = IpipeColpat_t.BLUE;
            prev_config.input.colp_elop = IpipeColpat_t.RED;
            prev_config.input.colp_elep = IpipeColpat_t.GREEN_RED;
        }else{
            Posix.stderr.printf("Ipiped: Invalid bayer pattern\n");
            return false;
        }
        set_previewer_config(&chan_config);
        return true;
    }

   /* Convertion gain from q10
    * Converts the gain from a int on fixed-point q10 into 2 ints, the integer 
    * part and the decimal part(9 bits) 
    */
    private void convertion_gains_from_q10(uint32 gain, int *decimal_gain, int *integer_gain)
    {
        *integer_gain = (int) (gain >> 10);
        *decimal_gain = (int) ((gain & 0x3ff) >> 1);
        return;
    }

    /* Convertion gain to q10
    * Converts a number separate on an integer and decimal parts into a int on 
    * fixed point
    */
    private void
    convertion_gains_to_q10(uint32 *gain, int decimal_gain, int integer_gain)
    {
        *gain = ((decimal_gain & 0x3ff)<<1)| ((integer_gain & 0xf)<<10); 
        return;
    }

    /**
     * Sets digital gain in the IPIPE, adjust a ratio gain of each color 
     * in the pattern(RGB) 
     * Each gain component can range from 0 to 15.998 in steps of 1/512
     * @param fd structure with file descriptors and owner flags
     * @param q10r_gain, in white balance module value for red component[0, 15.998]
     * @param q10g_gain, in white balance module value for green component[0, 15.998]
     * @param q10b_gain, in white balance module value for blue component[0, 15.998] 
     */
    private bool set_digital_gain_i(int *previewer_fd, char *owner_previewer_fd,
        uint32 q10r_gain, uint32 q10g_gain, uint32 q10b_gain)
    {
        ModuleParam mod_param = ModuleParam();
        Cap cap =  Cap();
        WhiteBalance wb = WhiteBalance();

        int gain_r_integer = 0, gain_g_integer = 0, gain_b_integer = 0;
        int gain_r_decimal = 0, gain_g_decimal = 0, gain_b_decimal = 0;

        if (q10r_gain > 0x3FFF)
            q10r_gain = 0x3FFF;
        if (q10g_gain > 0x3FFF)
            q10g_gain = 0x3FFF;
        if (q10b_gain > 0x3FFF)
            q10b_gain = 0x3FFF;

        convertion_gains_from_q10(q10r_gain, &gain_r_decimal, &gain_r_integer);
        convertion_gains_from_q10(q10g_gain, &gain_g_decimal, &gain_g_integer);
        convertion_gains_from_q10(q10b_gain, &gain_b_decimal, &gain_b_integer);

        cap.index = 0;
        if (*previewer_fd < 0) {
            /* Open previewer */
            *previewer_fd = open("/dev/davinci_previewer", O_RDWR);
            if (*previewer_fd < 0) {
                Posix.stderr.printf("\n Failed to open dm365 previewer device file");
                return false;
            }
            *owner_previewer_fd = 0;
        }
        /* Set operation mode */
        if (Posix.ioctl(*previewer_fd, PREV_ENUM_CAP, &cap) < 0) {
            Posix.stderr.printf("\n Failed to get previewer capabilities\n");
            return false;
        }

        cap.module_id = PREV_WB;
        strcpy(mod_param.version, cap.version);
        mod_param.module_id = cap.module_id;
        /*Sets red gain */
        wb.gain_r.integer = (ushort) gain_r_integer;
        wb.gain_r.decimal = (ushort) gain_r_decimal;
        /*Sets green-red gain */
        wb.gain_gr.integer = (ushort) gain_g_integer;
        wb.gain_gr.decimal = (ushort) gain_g_decimal;
        /*Sets green-blue gain */
        wb.gain_gb.integer = (ushort) gain_g_integer;
        wb.gain_gb.decimal = (ushort) gain_g_decimal;
        /*Sets blue gain */
        wb.gain_b.integer = (ushort) gain_b_integer;
        wb.gain_b.decimal = (ushort) gain_b_decimal;
        /*Sets offsets to zero */
        wb.ofst_r = 0;
        wb.ofst_gr = 0;
        wb.ofst_gb = 0;
        wb.ofst_b = 0;

        mod_param.len = (uint8)sizeof(WhiteBalance);
        mod_param.param = &wb;

        if (Posix.ioctl(*previewer_fd, PREV_S_PARAM, &mod_param) < 0) {
            Posix.stderr.printf("Error setting params to the previewer\n");
            if (*owner_previewer_fd == 0) {
                close(*previewer_fd);
            }
            return false;
        }
        if (debug){
            Posix.stdout.printf("Set red gain to %f\n", (float) q10r_gain / 1024);
            Posix.stdout.printf("Set green gain to %f\n", (float) q10g_gain / 1024);
            Posix.stdout.printf("Set blue gain to %f\n", (float) q10b_gain / 1024);
        }
        return true;
    }

    /**
     * Sets digital gain
     */
    public bool set_digital_gain(double _red_gain, double _green_gain, 
        double _blue_gain) throws IOError{

        uint32 q10r_gain = (uint32)((_red_gain + 1/512) * 1024);
        uint32 q10g_gain = (uint32)((_green_gain + 1/512) * 1024);
        uint32 q10b_gain = (uint32)((_blue_gain+ 1/512) * 1024);

        return set_digital_gain_i(&this.previewer_fd, &this.owner_previewer_fd, 
            q10r_gain, q10g_gain, q10b_gain);
    }

    /** Get the gain of each color component (RGB) of the white balance module. The 
     * returned gain values are on fixed-point Q10
     * Each gain component can range on float point from 0 to 15.998 in steps of 1/512
     * @param fd structure with file descriptors and owner flags
     * @param q10r_gain, in white balance module value for red component[0, 15.998]
     * @param q10g_gain, in white balance module value for green component[0, 15.998]
     * @param q10b_gain, in white balance module value for blue component[0, 15.998] 
     */
    private bool get_digital_gain_i(int *previewer_fd, char *owner_previewer_fd,
        uint32 *red_gain, uint32 *green_gain, uint32 *blue_gain)
    {
        Posix.stdout.printf("Digital gain\n");
        ModuleParam mod_param = ModuleParam();
        WhiteBalance wb = WhiteBalance();
        Cap cap =  Cap();
        cap.index = 0;
        if (*previewer_fd<0) {
            /* Open previewer */
            *previewer_fd = open("/dev/davinci_previewer", O_RDWR);
            if (*previewer_fd < 0) {
                Posix.stderr.printf("\n Failed to open dm365 previewer device file");
                return false;
            }
            *owner_previewer_fd = 0;
        }
        /* Set operation mode */
        if (Posix.ioctl(*previewer_fd, PREV_ENUM_CAP, &cap) < 0) {
            Posix.stderr.printf("\n Failed to get previewer capabilities\n");
            return false;
        }
        strcpy(mod_param.version, cap.version);
        mod_param.module_id = PREV_WB;
        mod_param.len = (uint8)sizeof(WhiteBalance);
        mod_param.param = &wb;

        if (Posix.ioctl(*previewer_fd, PREV_G_PARAM, &mod_param) < 0) {
            Posix.stderr.printf("Ipiped: Error in Setting params from driver\n");
            return false;
        }
        convertion_gains_to_q10(red_gain, wb.gain_r.decimal, wb.gain_r.integer);
        convertion_gains_to_q10(green_gain, wb.gain_gr.decimal,
            wb.gain_gr.integer);
        convertion_gains_to_q10(blue_gain, wb.gain_b.decimal,
            wb.gain_b.integer);
        return true;
    }

    /**
     * Gets digital gain
     */
    public bool get_digital_gain(out double _red_gain, out double _green_gain,
        out double _blue_gain) throws IOError{
        uint32 q10red_gain=0, q10green_gain=0, q10blue_gain=0;

        if (!get_digital_gain_i(&this.previewer_fd, &this.owner_previewer_fd,
                   &q10red_gain, &q10green_gain, &q10blue_gain)) {
            Posix.stderr.printf("Error:\n Failed to get the digital gain\n");
            return false;
        } else {
            _red_gain = ((double)(q10red_gain))/1024;
            _green_gain= ((double)(q10green_gain))/1024;
            _blue_gain = ((double)(q10blue_gain))/1024;
            return true;
        }
    }

    /**
     * Sets luminance adjustment
     * Sets the values for the brightness and the contrast on the ipipe's 
     * luminance adjusment module.
     * @param bright brightness Offset value for brightness control(U8 = 0 - +255)
     * @param contr contrast(U4.4 = 0 - +15.94)
     */
    public bool set_luminance_adj(int bright, double contr) throws IOError{
        ModuleParam mod_param = ModuleParam();
        LumAdj lum_adj = LumAdj();
        Cap cap = Cap();
        cap.index =0 ;
        uint8 q4contr;

        if (Posix.ioctl(this.previewer_fd , PREV_ENUM_CAP, &cap)<0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Error in Setting cap from driver\n");
            return false;
        }

        cap.module_id = PREV_LUM_ADJ;
        strcpy(mod_param.version,cap.version);
        mod_param.module_id = cap.module_id;

        if (bright > 0xFF) bright = 0xFF; 
        if (contr > 15.94) contr = 15.94;
        q4contr = (uint8)(contr * 16);
        lum_adj.brightness =(uchar)bright;
        lum_adj.contrast =(uchar)q4contr; 

        mod_param.len =(uint8)sizeof(LumAdj);
        mod_param.param = &lum_adj;

        if (Posix.ioctl(this.previewer_fd , PREV_S_PARAM, &mod_param) < 0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Error in Setting params from driver\n");
            Posix.close(this.previewer_fd );
            return false;
        }
        if (debug)
            Posix.stdout.printf("Set luminance adjustment to Brightness=%d," + 
            " Contrast=%f\n",bright,contr);
        return true;
    }

    /**
     * Gets luminance adjustment
     * Gets the values for the brightness and the contrast on the ipipe's 
     * luminance adjusment module
     */
    public bool get_luminance_adj(out int bright, out double contr) throws IOError{
        ModuleParam mod_param = ModuleParam();
        LumAdj lum_adj = LumAdj();
        Cap cap = Cap();
        cap.index =0 ;

        if (Posix.ioctl(this.previewer_fd , PREV_ENUM_CAP, &cap)<0) {
            if (debug)
                Posix.stderr.printf("Ipiped:Error in Setting cap from driver\n");
            return false;
        }

        strcpy(mod_param.version,cap.version);
        mod_param.module_id = PREV_LUM_ADJ;
        mod_param.len =(uint8)sizeof(LumAdj);
        mod_param.param = &lum_adj;

        if (Posix.ioctl(this.previewer_fd , PREV_G_PARAM, &mod_param) < 0){
            if (debug)
                Posix.stderr.printf("Ipiped:Error in Setting params from driver\n");
            Posix.close(this.previewer_fd );
            return false;
        }

        bright = lum_adj.brightness;
        contr = ((double)lum_adj.contrast)/16;

        return true;
    }

#if (RRAEW)
    public override bool get_video_processor_data(Interface *interf){
        *interf = dm365_vpfe_interface;
        return true;
    }
#endif
}
