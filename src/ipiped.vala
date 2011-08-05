/**
 * ipiped/src/ipiped.vala
 *
 * Ipipe class - framework for controlling and configuring ipipe using D-Bus messages
 *
 * Copyright(c) 2010, RidgeRun
 * All rights reserved.
*/

using Posix,V4l2,ImpPrev,dm365aew;
#if (RRAEW)
using rraew;
#endif
    [DBus(name = "com.ridgerun.ipiped.IpipeInterface", signals = "Error")]
    public class Ipipe:GLib.Object {

        /* Private data */
        /** Flag to enable/disable debug information */
        private static bool debug = false;
        /** Flag to indicate if the previewer is initialized*/
        private static bool initialized = false;
        private string sensor = "";
        private string video_processor = "";
        public AbstcVideoProcessor video_processor_abstract;
        public AbstcSensor sensor_abstract;
        public signal void Error(string err_message);
#if (RRAEW)
        /** Struct that contains auto white balance configuration*/
        RraewAwbConfiguration awb_config;
        /** Flag that indicates if auto white balance is configured or not*/
        bool awb_configured;
        /** Struct that contains auto exposure configuration*/
        RraewAeConfiguration ae_config;
         /** Flag that indicates if auto exposure's configuration status*/
        bool ae_configured;
        /** Struct that contains general aew configuration*/
        RraewConfiguration aew_config;
        /** Thread for aew*/
        unowned Thread<void*> thread;
        /** Flag to indicate if the aew thread is running*/
        bool aew_running = false;
        /** Indicates if we can close the execution thread wihtout failing **/
        bool clean_close = false;
        /** Pointer to aew structure*/
        void *rraew = null;
        /** Time between aew iterations*/
        int wait_time=0;
#endif
        /**
         * Create a new instance of a Ipipe daemon
         */
        public Ipipe(string _sensor, string _video_processor, 
            AbstcVideoProcessor _video_processor_abstract, 
            AbstcSensor _sensor_abstract){
           /* Initialize private variables */
            initialized = false;
            sensor =_sensor;
            video_processor=_video_processor;
            video_processor_abstract=_video_processor_abstract;
            sensor_abstract=_sensor_abstract;
            this.debug = false;
#if (RRAEW)
            this.ae_configured = false;
            this.awb_configured = false;
#endif
        }
        /**
         * Destroy a instance of Ipipe 
         */
        ~Ipipe(){
         /* Destroy the ipipe instance */
        }

         /**
         * Debug
         * Enable/Disable the debug information in all the functions
         * @param enable if true print debug information  
         */
        public void enable_debug(bool enable) throws IOError{
            this.debug = enable;
            video_processor_abstract.debug = true;
            sensor_abstract.debug = true;
        }
        /**
         * Ping
         * Show to the ipipe-client that an instance of the ipiped daemon is 
         * alive
         */
        public bool ping() throws IOError{ 
            return true;
        }

        /**
         * get_sensor
         * Return the sensor that is being used
         */
        public string get_sensor() throws IOError{
            return sensor;
        }

        /**
         * get_video_processor
         * Return the video processor that is being used*/
        public string get_video_processor() throws IOError{
            return video_processor;
        }

#if (RRAEW)
        /* aew_thread_func
         * This function consists on a loop that iterates
         * the execution of the rraew adjustments.
         * */
        private void* aew_thread_func(){
            try {
                /* When the flag aew_running is false
                 * stop aew*/
                while (aew_running) {
                    /*Wait the configured time between aew iterations*/
                    Thread.usleep(wait_time);
                    if (rraew_run(rraew)<0){
                        /*When an error occurs close aew*/
                        clean_close = false;
                        close_aew();
                    }
                }
            }catch(IOError e) {
                Posix.stderr.printf("Fail to execute:%s\n", e.message);
            }
            return null;
        }

        /**
         * set_auto_exposure_configuration
         * Initialize the ae struct for the auto exposure configuration of 
         * librraew.
         * @param ae string that chooses the auto exposure algorithm, can be 
         * "electronic-centric" or "none" (not apply an auto exposure).
         * @param meter string that chooses the metering system for the auto 
         * exposure algorithm, can be "partial", "center-weigthed", "segmented"
         * or "average"
         * @param rect_percentage defines the percentage of the image width 
         *  and height to be used as the center size. Default: 40
         * @param xrect x coordinate for the center point of the rectangle
         * of interest.
         * @param yrect y coordinate for the center point of the rectangle
         * of interest.
         */
        public int set_auto_exposure_configuration(string ae, string meter, 
            int rect_percentage, int xrect, int yrect) throws IOError{

            this.ae_config = RraewAeConfiguration();

             /* Define the ae algorithm*/
            if (ae == "electronic-centric")
                ae_config.algorithm = RraewExposureAlgo.EC;
            else if(ae == "none"){
                ae_config.algorithm = RraewExposureAlgo.NONE;
                this.ae_configured = true;
                return 0;
            } else {
                Posix.stderr.printf("\nIpiped:Invalid auto exposure algorithm\n");
                return -1;
            }

            /* Define the metering method*/
            if (meter == "partial")
                ae_config.meter_type = RraewMeteringType.PARTIAL_AREA;
            else if (meter == "weighted")
                ae_config.meter_type = RraewMeteringType.RECT_WEIGHTED;
            else if (meter == "average")
                ae_config.meter_type = RraewMeteringType.AVERAGE;
            else if (meter == "segmented")
                ae_config.meter_type = RraewMeteringType.SEGMENT;
            else{
                Posix.stderr.printf("\nIpiped:Invalid metering type\n");
                return -1;
            }
            /* Only the metering systems partial, rectangular weighted and 
             * average require the definition of the rectangle of interest*/
            if ((ae_config.meter_type == RraewMeteringType.PARTIAL_AREA) || 
                (ae_config.meter_type == RraewMeteringType.RECT_WEIGHTED) || 
                (ae_config.meter_type == RraewMeteringType.AVERAGE)){
                
                /*Sets the center point*/
                ae_config.rect_center_point.x = xrect;
                ae_config.rect_center_point.y = yrect;
                
                /* The point (-1, -1) es used as identifier for the 
                 * center of the image. So the auto exposure is 
                 * configured to center the rectangle*/
                if ((xrect == -1) && (yrect == -1)){
                    ae_config.rect_center_point.centered = 1;
                    ae_config.rect_center_point.x = 0;
                    ae_config.rect_center_point.y = 0;
                }
                /*Check percentage limits*/
                if ((rect_percentage > 100)|| (rect_percentage) < 1) {
                    Posix.stderr.printf("\nIpiped: rect_pecentage must be" + 
                        " between 1 and 100\n");
                    return -1;
                } 
                ae_config.rect_percentage = rect_percentage;
            }
            this.ae_configured = true;
            return 0;
        }

        /**
         * set_auto_white_balance_configuration
         * Initialize the awb struct for the auto white balance configuration of 
         * librraew.
         * @param wb string that chooses the auto white balance algorithm, 
         * can be "gray-world", "white-patch", "white-patch2"  or "none" (not 
         * apply an auto white balance).
         * @param g string that chooses the gain type, can be "sensor" for sensor 
         * gain or "digital" for digital gain on the SOC.
         */
        public int set_auto_white_balance_configuration(string wb, string g) 
            throws IOError{

            this.awb_config = RraewAwbConfiguration();

            /* Define the awb algorithm*/
            if (wb == "white-patch")
                awb_config.algorithm = RraewWhiteBalanceAlgo.WHITE_PATCH;
            else if (wb == "white-patch2")
                awb_config.algorithm = RraewWhiteBalanceAlgo.WHITE_PATCH_2;
            else if (wb == "gray-world")
                awb_config.algorithm = RraewWhiteBalanceAlgo.GRAY_WORLD;
            else if (wb == "none") {
                awb_config.algorithm = RraewWhiteBalanceAlgo.NONE;
                this.awb_configured = true;
                return 0;
            } else{
                Posix.stderr.printf("\nIpiped:Invalid white-balance algorithm\n");
                return -1;
            }
            
            /* Define the gain module to be used*/
            if (g == "sensor")
                awb_config.gain_type = RraewGainType.SENSOR;
            else if (g == "digital")
                awb_config.gain_type = RraewGainType.DIGITAL;
            else if (g == "default"){
                /*Digital is the default gain*/
                awb_config.gain_type = RraewGainType.DIGITAL;
            } else {
                Posix.stderr.printf("\nIpiped:Invalid gain type\n");
                return -1;
            }
            this.awb_configured = true;
            return 0;
        }

        /**
         * get_auto_exposure_configuration
         * Return current auto exposure's configuration
         */
        public int get_auto_exposure_configuration(out string ae, out string meter, 
            out int rect_percentage, out int xrect, out int yrect) throws IOError{

            if (ae_config.algorithm == RraewExposureAlgo.EC)
                ae = "electronic-centric";
            else 
                ae = "none";

            if ( ae_config.meter_type == RraewMeteringType.PARTIAL_AREA )
                meter = "partial";
            else if (ae_config.meter_type == RraewMeteringType.RECT_WEIGHTED)
                meter = "weighted";
            else if (ae_config.meter_type == RraewMeteringType.AVERAGE)
                meter = "average";
            else if (ae_config.meter_type == RraewMeteringType.SEGMENT)
                meter = "segmented";

            rect_percentage = ae_config.rect_percentage;

            if (ae_config.rect_center_point.centered == 1){
                xrect = -1;
                yrect = -1;
            } else {
                xrect = (int)ae_config.rect_center_point.x;
                yrect = (int)ae_config.rect_center_point.y;
            }

            if (!ae_configured)
                return -1;
            else
                return 0;
        }
        /**
         * get_auto_white_balance_configuration
         * Return the current configuration of the awb
         */
        public int get_auto_white_balance_configuration(out string wb, 
            out string g) throws IOError{
            if (!awb_configured){
                wb = "";
                g = "";
                return -1;
            }
            if (awb_config.algorithm == RraewWhiteBalanceAlgo.WHITE_PATCH)
                wb = "white-patch";
            else if (awb_config.algorithm == RraewWhiteBalanceAlgo.WHITE_PATCH_2)
                wb = "white-patch2";
            else if (awb_config.algorithm == RraewWhiteBalanceAlgo.GRAY_WORLD)
                wb = "gray-world";
            else if (awb_config.algorithm == RraewWhiteBalanceAlgo.NONE )
                wb = "none";

            if (awb_config.gain_type == RraewGainType.SENSOR)
                g = "sensor";
            else if (awb_config.gain_type == RraewGainType.DIGITAL)
                g = "digital";

            return 0;
        }

        /**
         * get_aew_status
         * Return the current configuration of the rraew library
         */
        public bool get_aew_status(out bool awb_config, out bool ae_config, 
            out int time, out int width, out int height, 
            out int segment_factor) throws IOError{

            awb_config = awb_configured;
            ae_config = ae_configured;
            time = wait_time;
            width = aew_config.width;
            height = aew_config.height;
            segment_factor = aew_config.segmentation_factor;
            return aew_running;
        }

        /**
         * get_ae_rectangle_coordinates
         * Get the rectangle of interest's coordinates, only if aew is running
         * and return it.
         */
        public int get_ae_rectangle_coordinates(out uint right, out uint left,
            out uint top, out uint bottom) throws IOError{

            if (aew_running) {
                if (rraew_get_rectangle_coordinates(rraew, &right, &left, 
                    &top, &bottom) == 0){
                    return 0;
                }
            }
            right = 0;
            left = 0;
            top = 0;
            bottom = 0;
            return -1;
        }
        /**
         * AEW Algorithm initialization
         * Uses the parameters given by the user to configure the aew library, 
         * sets the functions to access the sensor and the dm365 interface 
         * (vpfe ipipe). Creates an aew structure and a thread for the aew loop
         * @param time it is the time between aew algorithms iterations
         * @param width image width
         * @param height image height
         * @param segment_factor a percentage of the maximun image divisions 
         */
        public int init_aew(int time, int width, int height, 
            int segment_factor) throws IOError
        {
            /** File descriptors information*/
            RraewFileDescriptors fd = RraewFileDescriptors();
            wait_time = time;
            RraewSensor sensor = RraewSensor();
            RraewInterface interf = RraewInterface();
            aew_config = RraewConfiguration();

            /* If an instance of librraew is running close it 
             * before create a new one */
            if(aew_running) {
                close_aew();
                /*Wait for aew engine disable*/
                usleep(300000);
            }

            /* Defining general rraew params */
            aew_config.height = height;
            aew_config.width = width;
            aew_config.segmentation_factor = segment_factor;

            /* Check params limits */
            if (time > 1000000) {
                Posix.stderr.printf("\nIpiped:Wait time is greater than the maximum\n");
                return -1;
            }

            if ((segment_factor > 100)|| (segment_factor) < 1) {
                Posix.stderr.printf("\nIpiped:Segmentation factor must be between 1 and 100\n");
                return -1;
            } 

            /* Get sensor information */
            sensor_abstract.get_sensor_data(&sensor);
            /* Get video processor information */
            if (!video_processor_abstract.get_video_processor_data(&interf)) {
                Posix.stderr.printf ("Can't get video processor data\n");
                return -1;
            }
            /* Defining ipiped file descriptors */
            fd.previewer_fd = video_processor_abstract.previewer_fd;
            fd.owner_previewer_fd = video_processor_abstract.owner_previewer_fd;
            fd.aew_fd = video_processor_abstract.aew_fd;
            fd.owner_aew_fd = video_processor_abstract.owner_aew_fd;
            fd.capture_fd = sensor_abstract.capture_fd;
            fd.owner_capture_fd = sensor_abstract.owner_capture_fd;

            /* Create rraew handler */
            rraew = rraew_create(&awb_config, &ae_config, &aew_config, 
                &sensor, &interf, &fd);
            if (rraew == null){
                Posix.stderr.printf ("Can't create rraew handler\n");
                return -1;
            }
            /* Enable aew flag */
            aew_running = true;
            clean_close = true;

            /* Create a new thread for the aew loop*/
            if (!Thread.supported ()) {
                    error ("Cannot run without thread support");
            }
            try {
                thread = Thread.create<void*>(aew_thread_func, true);
            } catch (ThreadError e) {
                return -1;
            }
            return 0;
        }

        /**
         * End AEW Algorithm, disable AEW engine
         */
        public void close_aew() throws IOError{
            /*Clean the flag that indicates aew 
             * is running*/
            aew_running = false;
            /*Check if the aew wasn't close by  
             *librraew error*/
            if(clean_close) {
                /*join the thread*/
                thread.join();
                clean_close = false;
            }
            /*If the rraew handler was initialized
             *destroy it*/
            if (rraew != null){
                rraew_destroy(rraew);
                rraew = null;
            }
        }
#endif
    }

