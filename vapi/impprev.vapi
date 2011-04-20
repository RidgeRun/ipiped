/*
 * impprev.vapi
 * Copyright RidgeRun (C) 2010
 * Author: 
 *
 */
 
 [CCode (lower_case_cprefix = "",
       cheader_filename = "media/davinci/imp_common.h,media/davinci/imp_previewer.h,media/davinci/dm365_ipipe.h,media/davinci/dm3xx_ipipe.h")]
namespace ImpPrev {


    [CCode (cname = "IMP_MODE_CONTINUOUS")]
    public const int MODE_CONTINUOUS;

    [CCode (cname = "PREV_MODE_SINGLE_SHOT")]
    public const int MODE_SINGLE_SHOT;
    
    [CCode (cname = "IMP_MAX_NAME_SIZE")]
    public const int MAX_NAME_SIZE;

    [CCode (cname = "struct prev_channel_config")]
    /**
     * Structure for configuring the previewer driver
     * used in PREV_SET_CONFIG/PREV_GET_CONFIG ioctls
     */
    public struct ChannelConfig {
        public uint oper_mode;
        public ushort len;
        public void* @config;
    }

    [CCode (cprefix = "IMP_", cname = "int")]
    public enum DataPaths {
        RAW2RAW = 1,
        RAW2YUV = 2,
        YUV2YUV = 4
    }

    [CCode (cname = "struct prev_cap")]
    /**
     * Structure used by application to query the modules
     * available in the ImageProcessor
     */
    //[SimpleType]
    public struct Cap {
        public uint8 index;
        public unowned string version;
        public uint8 module_id;
        public char control;
        public DataPaths path;
        public unowned string module_name;
    }

    [CCode (cname = "struct prev_module_param")]
    /**
     * Structure to configure preview modules.Used by
     * PREV_SET_PARAM or PREV_GET_PARAM ioctls
     */
    public struct ModuleParam {
        public unowned string version;
        public uint8 len;
        public uint8 module_id;
        public void* @param;
    }

    [CCode (cname = "struct ipipe_float_u16")]
    public struct Float_u16 {
        public ushort integer;
        public ushort decimal;
    }

    [CCode (cname = "struct ipipe_float_s16")]
    public struct Float_s16 {
        public short integer;
        public ushort decimal;
    }

    [CCode (cname = "struct prev_wb")]
        /**
         *  Structure to configure WB module
         */
    public struct WhiteBalance {
        public short ofst_r;
        public short ofst_gr;
        public short ofst_gb;
        public short ofst_b;
        public Float_u16 gain_r;
        public Float_u16 gain_gr;
        public Float_u16 gain_gb;
        public Float_u16 gain_b;
    }

    [CCode (cname = "struct prev_lum_adj")]
        /** 
         * Structure to configure Luminance Adjustment module 
         */
    public struct LumAdj {

        uint8 brightness;
        uint8 contrast;
    }

    [CCode (cname = "struct prev_rgb2rgb")]
    /**
     * Struct for configuring RGB2RGB blending module 
     */
    public struct PrevRgb2rgb {

        Float_s16 coef_rr;
        Float_s16 coef_gr;
        Float_s16 coef_br;
        Float_s16 coef_rg;
        Float_s16 coef_gg;
        Float_s16 coef_bg;
        Float_s16 coef_rb;
        Float_s16 coef_gb;
        Float_s16 coef_bb;
        int out_ofst_r;
        int out_ofst_g;
        int out_ofst_b;
    }
    
    [CCode (cprefix = "IPIPEIF_DECIMATION_")]
    public enum IpipeifDecimation {
        OFF,
        ON
    }
    
    [CCode (cname = "struct ipipeif_dpc")]
    /* DPC at the if for IPIPE 5.1 */
    public struct IpipeifDpc {
        /* 0 - disable, 1 - enable */
        public uchar en;
        /* threshold */
        public ushort thr;
    }
    
    [CCode (cprefix = "IPIPE_BYPASS_")]
    public enum DpathsBypass_t {
        OFF,
        ON
    }
    
    [CCode (cprefix = "IPIPE_")]
    public enum IpipeColpat_t {
        RED,
        GREEN_RED,
        GREEN_BLUE,
        BLUE
    }

    [CCode (cname = "struct prev_cont_input_spec")]

    public struct PrevContInputSpec {
        /* 1 - enable, 0 - disable df subtraction */
        public uchar en_df_sub;
        /* DF gain enable */
        public uchar en_df_gain;
        /* DF gain value */
        public uint df_gain;
        /* DF gain threshold value */
        public ushort df_gain_thr;
        /* Enable decimation 1 - enable, 0 - disable
         * This is used for bringing down the line size
         * to that supported by IPIPE. DM355 IPIPE
         * can process only 1344 pixels per line.
         */
        public IpipeifDecimation dec_en;
        /* used when en_dec = 1. Resize ratio for decimation
         * when frame size is  greater than what hw can handle.
         * 16 to 112. IPIPE input width is calculated as follows.
         * width = image_width * 16/ipipeif_rsz. For example
         * if image_width is 1920 and user want to scale it down
         * to 1280, use ipipeif_rsz = 24. 1920*16/24 = 1280
         */
        public uchar rsz;
        /* Enable/Disable avg filter at IPIPEIF.
         * 1 - enable, 0 - disable
         */
        public uchar avg_filter_en;
        /* Gain applied at IPIPEIF. 1 - 1023. divided by 512.
         * So can be from 1/512 to  1/1023.
         */
        public ushort gain;
        /* clipped to this value at the output of IPIPEIF */
        public ushort clip;
        /* Align HSync and VSync to rsz_start */
        public uchar align_sync;
        /* ipipeif resize start position */
        public uint rsz_start;
        /* Simple defect pixel correction based on a threshold value */
        public IpipeifDpc dpc;
        /* Color pattern for odd line, odd pixel */
        public IpipeColpat_t colp_olop;
        /* Color pattern for odd line, even pixel */
        public IpipeColpat_t colp_olep;
        /* Color pattern for even line, odd pixel */
        public IpipeColpat_t colp_elop;
        /* Color pattern for even line, even pixel */
        public IpipeColpat_t colp_elep;
    }

    [CCode (cname = "struct prev_continuous_config")]
    /**
     * Struct for configuring Continuous mode in the 
     * previewer channel 
     */
    public struct PreContinuosConfig {
        DpathsBypass_t bypass;
        PrevContInputSpec input;
    }

    public const int PREV_S_PARAM;
    public const int PREV_G_PARAM;
    public const int PREV_ENUM_CAP;
    public const int PREV_S_CONFIG;
    public const int PREV_G_CONFIG;
    public const int PREV_S_OPER_MODE;
    public const int PREV_G_OPER_MODE;
    public const int IMP_MAX_NAME_SIZE;
    public const uint8 PREV_WB;
    public const uint8 PREV_LUM_ADJ;
    public const uint8 PREV_RGB2RGB_1;
 
}
