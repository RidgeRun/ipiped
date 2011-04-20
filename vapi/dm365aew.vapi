/*
 * dm365aew.vapi
 * Copyright RidgeRun (C) 2010
 * Author: Maria Haydee Rodriguez
 *
 */
 
 [CCode (lower_case_cprefix = "",
       cheader_filename = "media/davinci/dm365_aew.h")]

namespace dm365aew {


        [CCode (cprefix = "H3A_AEW_")]
        /* Enum for Enable/Disable specific feature */
        public enum AewEnableFlag {
                DISABLE,
                ENABLE
        }

        [CCode (cprefix = "AEW_OUT_")]
        /* AE/AWB output format */
        public enum AewOutputFormat {
                SUM_OF_SQUARES,
                MIN_MAX,
                SUM_ONLY
        }

        [CCode (cname = "struct aew_hmf")]
        /* Contains the information regarding the Horizontal Median Filter */
        public struct AewHmf {
            /* Status of Horizontal Median Filter */
            AewEnableFlag enable;
            /* Threshhold Value for Horizontal Median Filter. Make sure
            * to keep this same as AF threshold since we have a common
            * threshold for both
            */
            uint threshold;
        }

        [CCode (cname = "struct aew_window")]
        /* Contains the information regarding Window Structure in AEW Engine */
        public struct AewWindow {
            /* Width of the window */
            uint width;
            /* Height of the window */
            uint height;
            /* Horizontal Start of the window */
            uint hz_start;
            /* Vertical Start of the window */
            uint vt_start;
            /* Horizontal Count */
            uint hz_cnt;
            /* Vertical Count */
            uint vt_cnt;
            /* Horizontal Line Increment */
            uint hz_line_incr;
            /* Vertical Line Increment */
            uint vt_line_incr;
        }

        [CCode (cname = "struct aew_black_window")]
        /* Contains the information regarding the AEW Black Window Structure */
        public struct AewBlackWindow {
            /* Height of the Black Window */
            uint height;
            /* Vertical Start of the black Window */
            uint vt_start;
        }


        [CCode (cname = "struct aew_configuration")]
        public struct AewConfiguration {
            /* A-law status */
            AewEnableFlag alaw_enable;
            /* AE/AWB output format */
            AewOutputFormat out_format;
            /* AW/AWB right shift value for sum of pixels */
            char sum_shift;
            /* Saturation Limit */
            int saturation_limit;
            /* HMF configurations */
            AewHmf hmf_config;
            /* Window for AEW Engine */
            AewWindow window_config;
            /* Black Window */
            AewBlackWindow blackwindow_config;
        }

        public const int AEW_S_PARAM;
        public const int AEW_ENABLE;
        public const int AEW_DISABLE;

}
