/**
 * ipiped/src/ipiped.vala
 *
 * Ipipe class - framework for controlling and configuring ipipe using D-Bus messages
 *
 * Copyright(c) 2010, RidgeRun
 * All rights reserved.
 *
 * GPL2 license - See http://www.opensource.org/licenses/gpl-2.0.php for complete text.
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
        public Ipipe(string _sensor, string _video_processor, AbstcVideoProcessor _video_processor_abstract, 
            AbstcSensor _sensor_abstract){
           /* Initialize private variables */
            initialized = false;
            sensor =_sensor;
            video_processor=_video_processor;
            video_processor_abstract=_video_processor_abstract;
            sensor_abstract=_sensor_abstract;
            this.debug = false;
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

        public string get_sensor() throws IOError{
            return sensor;
        }

        public string get_video_processor() throws IOError{
            return video_processor;
        }

#if (RRAEW)
        private void* aew_thread_func(){
            try {
                while (aew_running) {
                    Thread.usleep(wait_time);
                    if (run_rraew(rraew)<0){
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
         * AEW Algorithm initialization
         * Uses the parameters given by the user to configure the aew library, 
         * sets the functions to access the sensor and the dm365 interface 
         * (vpfe ipipe). Creates an aew structure and a thread for the aew loop
         * @param wb string that chooses the auto white balance algorithm, 
         * can be "G" for gray world or "W" for white balance  or "N" to do not 
         * apply an auto white balance.
         * @param ae string that chooses the auto exposure algorithm, can be 
         * "EC" for electronic centric or "N" to do not apply an auto exposure.
         * @param g string that chooses the gain type, can be "S" for sensor 
         * gain or "D" for digital gain.
         * @param meter string that chooses the metering system for the auto 
         * exposure algorithm, can be "S" for spot or "P" for partial or "C" for 
         * electronic centric or "SG" for segmented image or "A" for average.
         * @param time it is the time between aew algorithms iterations
         * @param fps is the minimum allowed frame rate
         * @param segment_factor a percentage of the maximun image divisions 
         */
        public int init_aew(string wb, string ae, string g, string meter, 
            int time, int fps, int segment_factor, int width, int height, 
            int center_percentage) throws IOError
        {
            /** File descriptors information*/
            FileDescriptors fd = FileDescriptors();

            wait_time = time;
            WhiteBalanceAlgo wb_algo;
            ExposureAlgo ae_algo;
            GainType gain_type;
            MeteringType meter_type;
            Sensor sensor = Sensor();
            Interface interf = Interface();

            if(aew_running) {
                Posix.stderr.printf("The AEW algorithm is alreadty being " + 
                    "executed. Please finish the current session\n by using " + 
                    "close-aew. Then you will be able to start a new one\n");
                return -1;
            }

            if (time > 1000000) {
                Posix.stderr.printf("\nIpiped:Wait time is greater than the maximum\n");
                return -1;
            }

             if ((segment_factor > 100)|| (segment_factor) < 1) {
                Posix.stderr.printf("\nIpiped:Segmentation factor must be between 1 and 100\n");
                return -1;
            } 

            /* Define the gain module to be used*/
            if (g == "S")
                gain_type = GainType.SENSOR;
            else if (g == "D")
                gain_type = GainType.DIGITAL;
            else {
                Posix.stderr.printf("\nIpiped:Invalid gain type\n");
                return -1;
            }
            /* Define the ae algorithm*/
            if (ae == "EC")
                ae_algo = ExposureAlgo.EC;
            else if(ae == "N")
                ae_algo = ExposureAlgo.NONE;
            else {
                Posix.stderr.printf("\nIpiped:Invalid auto exposure algorithm\n");
                return -1;
            }
            /* Define the awb algorithm*/
            if (wb == "W")
                wb_algo = WhiteBalanceAlgo.WHITE_PATCH;
            else if (wb == "W2")
                wb_algo = WhiteBalanceAlgo.WHITE_PATCH_2;
            else if (wb == "G")
                wb_algo = WhiteBalanceAlgo.GRAY_WORLD;
            else if (wb == "N")
                wb_algo = WhiteBalanceAlgo.NONE;
            else{
                Posix.stderr.printf("\nIpiped:Invalid white-balance algorithm\n");
                return -1;
            }
            /* Define the metering method*/
            if (meter == "P")
                meter_type = MeteringType.PARTIAL_AREA;
            else if (meter == "C")
                meter_type = MeteringType.CENTER_WEIGHTED;
            else if (meter == "A")
                meter_type = MeteringType.AVERAGE;
            else if (meter == "SG"){
                meter_type = MeteringType.SEGMENT;
            }else{
                Posix.stderr.printf("\nIpiped:Invalid metering type\n");
                return -1;
            }

            /* Sensor information */
            sensor_abstract.get_sensor_data(&sensor);
            if (!video_processor_abstract.get_video_processor_data(&interf)) {
                Posix.stderr.printf ("Can't get video processor data\n");
                return -1;
            }

            fd.previewer_fd = video_processor_abstract.previewer_fd;
            fd.owner_previewer_fd = video_processor_abstract.owner_previewer_fd;
            fd.aew_fd = video_processor_abstract.aew_fd;
            fd.owner_aew_fd = video_processor_abstract.owner_aew_fd;
            fd.capture_fd = sensor_abstract.capture_fd;
            fd.owner_capture_fd = sensor_abstract.owner_capture_fd;

            rraew = create_rraew(wb_algo, ae_algo, meter_type, 
                width, height, fps, segment_factor, center_percentage, gain_type, 
                &fd, &sensor, &interf);

            aew_running = true;
            clean_close = true;
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
            aew_running = false;
            if(clean_close) {
                thread.join();
                clean_close = false;
            }
            if (rraew != null){
                destroy_rraew(rraew);
                rraew = null;
            }
        }
#endif
    }

