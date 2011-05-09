using V4l2;
#if (RRAEW)
using rraew;
#endif
[DBus (name = "com.ridgerun.mt9p031Interface")]
public class Ipiped_mt9p031 : AbstcSensor{
    /**
     * Create a new instance of a Ipipe daemon
     */
    public Ipiped_mt9p031(){
        /* Initialize private variables */
        this.debug = false;
        this.capture_fd = -1;
        this.owner_capture_fd = 1;
    }

    /**
     * Open sensor
     * Open the video capture device, obtain the correspondly file 
     * descriptor */
    private int open_sensor(){
        /* Open the sensor device*/
        this.capture_fd  = Posix.open("/dev/video0", Posix.O_RDWR | Posix.O_NONBLOCK, 0);
        if (this.capture_fd < 0){
            Posix.stderr.printf("Failed to open sensor\n");
            return -1;
        }
        this.owner_capture_fd = 0;
        return 0;
    }

   /**
    * Sets sensor gain for each color R, Gr, Gb, B (mt9p031)
    * Each gain component can range from 1 to 128 in steps of:
    *      0.125 if gain between 1 and 4
    *      0.250 if gain between 4.25 and 8
    *      1.000 if gain betwewn 8 and 128
    * @param fd structure with file descriptors and owner flags
    * @param r_gain red gain [1, 128]
    * @param g_gain green gain [1, 128]
    * @param b_gain blue gain [1, 128]
    */
    private int set_sensor_gain_i(int *capture_fd, char *owner_capture_fd, 
        uint32 q10r_gain, uint32 q10g_gain, uint32 q10b_gain){

        Control ctrl = Control();
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }

        ctrl.id =UserClassControlIds.RED_BALANCE;
        ctrl.value =(int)(q10r_gain >> 7);
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)) {
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed:red\n");
            return -1;
        }

        ctrl.id =UserClassControlIds.BRIGHTNESS; //V4L2_CID_GREEN1_BALANCE;
        ctrl.value =(int)(q10g_gain >> 7);
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)) {
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed:green1\n");
            return -1;
        }

        ctrl.id =UserClassControlIds.AUTOGAIN; //V4L2_CID_GREEN2_BALANCE;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)) {
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed:green2\n");
            return -1;
        }

        ctrl.id =UserClassControlIds.BLUE_BALANCE;
        ctrl.value =(int)(q10b_gain >> 7);
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)) {
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed:blue\n");
            return -1;  
        }

        if (debug)
            Posix.stdout.printf("Set gain in the sensor  r=%f, g=%f ,b=%f\n",
            (float)(q10r_gain)/1024, (float)(q10g_gain)/1024, 
            (float)(q10b_gain)/1024);
        return 0; 
    }

    /** 
     * Set sensor gain
     * Cast the float RGB gains to fixed-point q3 and use the 
     * set_sensor_gain_st function to ajust the sensor gains
     */
    public int set_sensor_gain(double r_gain, double g_gain, double b_gain) throws IOError{
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        uint32 q10r_gain = (uint32)((r_gain + 0.125/2) * 1024);
        uint32 q10g_gain = (uint32)((g_gain + 0.125/2) * 1024);
        uint32 q10b_gain = (uint32)((b_gain+ 0.125/2) * 1024);
        return set_sensor_gain_i(&this.capture_fd, &this.owner_capture_fd,
            q10r_gain, q10g_gain, q10b_gain);
    }

    /**
     * Get the combined gain of each color in the sensor registers. 
     * Each gain component can range from 1 to 128 in steps of:
     *      0.125 if gain between 1 and 4
     *      0.250 if gain between 4.25 and 8
     *      1.000 if gain betwewn 8 and 128
     * @param fd structure with file descriptors and owner flags
     * @param r_gain pointer to get the red gain
     * @param g_gain pointer to get the green gain
     * @param b_gain pointer to get the blue gain
     */
     private int get_sensor_gain_i(int *capture_fd, char *owner_capture_fd, 
        uint32 *q10r_gain, uint32 *q10g_gain, uint32 *q10b_gain){
        Control ctrl = Control();
        if (this.capture_fd < 0){
            Posix.stderr.printf("Fail get sensor gain\n");    
            return -1;
        } 
        /* Get Red Gain */
        ctrl.id = UserClassControlIds.RED_BALANCE;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get red balance\n");
            return -1; 
        }
        *q10r_gain = ctrl.value << 7;
        /* Get Blue Gain */
        ctrl.id = UserClassControlIds.BLUE_BALANCE;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get red balance\n");
            return -1; 
        }
        *q10b_gain = ctrl.value << 7;
        /* Get Green1 Gain */
        ctrl.id = UserClassControlIds.BRIGHTNESS;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get red balance\n");
            return -1; 
        }
        *q10g_gain = ctrl.value << 7;
        return 0;
    } 
    /** 
     * Get sensor gain
     * Use the get_sensor_gain_i function to obtain the RGB sensor gains 
     * and print them
     */
    public bool get_sensor_gain(out double _red_gain, out double _green_gain,
        out double _blue_gain) throws IOError{
        uint32 q10red_gain=0,q10green_gain=0,q10blue_gain=0;
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return false;
        }

        if (get_sensor_gain_i(&this.capture_fd, &this.owner_capture_fd,
                   &q10red_gain, &q10green_gain, &q10blue_gain) != 0) {
            Posix.stderr.printf("Error:\n Failed to get the sensor gain\n");
            return false;
        } else {
            _red_gain = ((double)(q10red_gain))/1024;
            _green_gain= ((double)(q10green_gain))/1024;
            _blue_gain = ((double)(q10blue_gain))/1024;
            return true;
        }
    }

    /**
     * Flip the image vetically 
     * Change the state of the vertical flip flag to reverse the image's 
     * rows. When mirroring the rows, the bayer pattern is preserved for 
     * the pixel order, that means the bayer pattern readout is reversed as the pixels.
     * @param state is an on/off flag. If the value is 1 image's columns 
     * must be reversed, if 0 they must not
     */
    public int sensor_flip_vertically(string state) throws IOError{
        Control ctrl = Control();
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        if (state == "ON"){
            ctrl.value = 1;
        }else if (state == "OFF"){
            ctrl.value = 0;
        }else {
            if (debug)
                Posix.stderr.printf("Ipiped: Invalid vertical flip state\n");
                return -1;
        }
        ctrl.id = UserClassControlIds.VFLIP;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed:" + 
                    "vertical flip\n");
            return -1; 
        }
        return 0;
    }

    /**
     * Flip the image horizontally 
     * Change the state of the horizontal flip flag to reverse the image's 
     * columns. When mirroring the columns, the bayer pattern is preserved 
     * for the pixel order, that means the bayer pattern readout is reversed 
     * as the pixels.
     * @param state is an on/off flag. If the value is 1 image's columns 
     * must be reversed, if 0 they must not
     */
    public int sensor_flip_horizontally(string state) throws IOError{
        Control ctrl = Control();

        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        if (state == "ON"){
            ctrl.value = 1;
        }else if (state == "OFF"){
            ctrl.value = 0;
        }else {
            if (debug)
                Posix.stderr.printf("Ipiped: Invalid horizontal flip state\n");
            return -1;
        }
        ctrl.id = UserClassControlIds.HFLIP;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed: " + 
                "horizontal flip\n");
            return -1; 
        }
        return 0;
    }

    /**
     * Sets exposure time 
     * Sets the effective shutter time that is the integration time for 
     * the light in the CMOS sensor receptors
     * @param fd structure with file descriptors and owner flags
     * @param exp_time exposure time in us
     */
    private int set_exposure_time_i(int *capture_fd, char *owner_capture_fd,
        uint32 exp_time){
        Control ctrl = Control();
        ctrl.id = UserClassControlIds.EXPOSURE;
        ctrl.value = (int32)(exp_time)<<8;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_S_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_S_CTRL failed: set exposure time\n");
            return -1; 
        }
        if (debug)
            Posix.stdout.printf("Set exposure time to: %u\n", exp_time);
        return 0; 
    }

    public int set_exposure_time(int _exp_time) throws IOError{
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        return set_exposure_time_i(&this.capture_fd, &this.owner_capture_fd,
            _exp_time); 
    }

    /**
     * Get exposure time
     * Obtain from the sensor the actual ligth integration time
     * @param fd structure with file descriptors and owner flags
     * @param exp_time pointer where the function leave the exposure time in us  
     */
    private int get_exposure_time_i(int *capture_fd, char *owner_capture_fd,
        uint32* exp){
        Control ctrl = Control();
        ctrl.id = UserClassControlIds.EXPOSURE;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug == true)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get exposure"+
                " time\n");
            return -1; 
        }
        *exp = ctrl.value>>8;
        return 0;
    }


    public bool get_exposure_time(out int exp_time) throws IOError{
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return false;
        }
   
        if (get_exposure_time_i(&this.capture_fd, &this.owner_capture_fd, &exp_time) != 0) {
            Posix.stderr.printf("Error:\n Failed to get the exposure time\n");
            return false;
        } 
        
        return true;
    }
    
#if (RRAEW)

    /*Internal methods*/
    /**
     * Get the frame vertical orientation (mt9p031)
     * @param vf is an on/off flag. If the value is 1 image's rows are 
     * reversed, if 0 they are not
     */
    private int get_vertical_flip(int *vf){
        Control ctrl = Control();
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        /* Get vertical flip of the sensor */
        ctrl.id = UserClassControlIds.VFLIP;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get vertical flip\n");
            return -1; 
        }
        *vf = ctrl.value; 
        return 0;
    }

    /**
     * Get the frame horizontal orientation (mt9p031)
     * @param hf is an on/off flag. If the value is 1 image's columns are 
     * reversed, if 0 they are not
     */ 
    private int get_horizontal_flip(int *hf){
        Control ctrl = Control();
        if (this.capture_fd < 0){
            if (open_sensor() < 0)
                return -1;
        }
        /* Get horizontal flip of the sensor */
        ctrl.id = UserClassControlIds.HFLIP;
        if (-1 == Posix.ioctl(this.capture_fd , VIDIOC_G_CTRL, &ctrl)){
            if (debug)
                Posix.stderr.printf("ioctl:VIDIOC_G_CTRL failed: get vertical flip\n");
            return -1; 
        }
        *hf = ctrl.value;
        return 0;
    }
    
    /**
     * Get the pixel position for each color pattern
     * @param color_pattern, array that contains the pixel position
     *                       of R, Gr, Gb and B 
     */
    private bool get_color_pattern(ColorPattern color_pattern){
        int vf=0, hf=0;
        int ret = 0;

        /* Get the frame orientation */ 
        ret = get_vertical_flip(&vf);
        ret += get_horizontal_flip(&hf);
        if (ret != 0) {
            if (debug)
                Posix.stderr.printf ("Error:\n Failed to get frame orientation\n");
            return false;
        }
        /* Define pixels order */
        if (vf==1 && hf==1){
            /* Pattern:
             *  Gb B
             *  R  Gr */
            color_pattern = colorptn_GbBRGr;
        } else if (vf==0 && hf ==1){
            /* Pattern:
             *  R  Gr
             *  Gb B */
            color_pattern = colorptn_RGrGbB;
        } else if (vf==1 && hf ==0){
            /* Pattern:
             *  B  Gb
             *  Gr R*/
            color_pattern = colorptn_BGbGrR;
        } else {
            /* Pattern:
             *  Gr R
             *  B  Gb */
            color_pattern = colorptn_GrRBGb;        
        }
        return true;
    }

    public override int get_sensor_data(Sensor *sensor){
        ColorPattern colorptn = ColorPattern();
        if (!get_color_pattern (colorptn)){
            Posix.stderr.printf ("Error:\n Failed to get color pattern\n");
            return -1;
        }
        sensor.colorptn = colorptn;
        sensor.max_exp_time = 2500;
        sensor.min_exp_time = 1;
        sensor.max_gain = 128;
        sensor.min_gain = 1;
        sensor.n_gain_steps = 3;
        sensor.gain_steps = (GainStep*)malloc(sensor.n_gain_steps*sizeof(GainStep));
        sensor.gain_steps[0].range_end = 4;
        sensor.gain_steps[0].step_n = 1;
        sensor.gain_steps[0].step_d = 8; 

        sensor.gain_steps[1].range_end = 8;
        sensor.gain_steps[1].step_n = 1;
        sensor.gain_steps[1].step_d = 4; 

        sensor.gain_steps[2].range_end = 128;
        sensor.gain_steps[2].step_n = 1;
        sensor.gain_steps[2].step_d = 1; 

        sensor.set_gain = set_sensor_gain_i;
        sensor.get_gain = get_sensor_gain_i;
        sensor.set_exposure = set_exposure_time_i;
        sensor.get_exposure = get_exposure_time_i;
        return 0;
    }
#endif
}
