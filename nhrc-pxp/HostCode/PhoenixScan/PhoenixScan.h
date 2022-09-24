/******************************************************************************/
/* Phoenix SX Radio Programmer -- Copyright (C) 2001, NHRC LLC.               */
/******************************************************************************/

#define DLG_MAIN 200

#ifdef SCAN
#define APPTITLE "PhoenixScan"
#define APPNAME "PhoenixScan"
#define APPNAME_RAW PhoenixScan
#define ICON_NAME "PhoenixScan.ico"
#else
#define APPTITLE "Phoenix"
#define APPNAME "Phoenix"
#define APPNAME_RAW Phoenix
#define ICON_NAME "Phoenix.ico"
#endif
#define VERSION   "1.01"
#define RVERSION   1, 0, 0, 32
#define COPYRIGHT "Copyright \251 2001, 2006 NHRC LLC."
#define BUILDDATE "30 May 2006"

/* Menu Tags */
#define FILE_NEW	        2001
#define FILE_LOAD	        2002
#define FILE_SAVE	        2003
#define FILE_SAVE_AS	        2004
#define FILE_PRINT	        2005
#define FILE_EXIT	        2006
#define POD_GET	                2011
#define POD_PUT  	        2012
#define POD_READ  	        2013
#define POD_WRITE 	        2014
#define HELP_PROGRAM            2021
#define HELP_ABOUT              2022

/* AboutBox Controls */
#define ABOUT_TEXT              3001

/* PrintingDialog controls */
#define PRINT_DIALOG_STATUS     4001

/* control identifiers */
#define TX_CTL_OFFSET      1
#define TX_TONE_CTL_OFFSET 2
#define RX_CTL_OFFSET      3
#define RX_TONE_CTL_OFFSET 4
#define STE_CTL_OFFSET     5
#define CCT_CTL_OFFSET     6

#define CH_CTL_OFFSET   1000

#define IDC_CH1_LABEL	1010
#define IDC_CH1_TX	1011
#define IDC_CH1_TX_TONE	1012
#define IDC_CH1_RX	1013
#define IDC_CH1_RX_TONE	1014
#define IDC_CH1_STE	1015
#define IDC_CH1_CCT	1016

#define IDC_CH2_LABEL	1020
#define IDC_CH2_TX	1021
#define IDC_CH2_TX_TONE	1022
#define IDC_CH2_RX	1023
#define IDC_CH2_RX_TONE	1024
#define IDC_CH2_STE	1025
#define IDC_CH2_CCT	1026

#define IDC_CH3_LABEL	1030
#define IDC_CH3_TX	1031
#define IDC_CH3_TX_TONE	1032
#define IDC_CH3_RX	1033
#define IDC_CH3_RX_TONE	1034
#define IDC_CH3_STE	1035
#define IDC_CH3_CCT	1036

#define IDC_CH4_LABEL	1040
#define IDC_CH4_TX	1041
#define IDC_CH4_TX_TONE	1042
#define IDC_CH4_RX	1043
#define IDC_CH4_RX_TONE	1044
#define IDC_CH4_STE	1045
#define IDC_CH4_CCT	1046

#define IDC_CH5_LABEL	1050
#define IDC_CH5_TX	1051
#define IDC_CH5_TX_TONE	1052
#define IDC_CH5_RX	1053
#define IDC_CH5_RX_TONE	1054
#define IDC_CH5_STE	1055
#define IDC_CH5_CCT	1056

#define IDC_CH6_LABEL	1060
#define IDC_CH6_TX	1061
#define IDC_CH6_TX_TONE	1062
#define IDC_CH6_RX	1063
#define IDC_CH6_RX_TONE	1064
#define IDC_CH6_STE	1065
#define IDC_CH6_CCT	1066

#define IDC_CH7_LABEL	1070
#define IDC_CH7_TX	1071
#define IDC_CH7_TX_TONE	1072
#define IDC_CH7_RX	1073
#define IDC_CH7_RX_TONE	1074
#define IDC_CH7_STE	1075
#define IDC_CH7_CCT	1076

#define IDC_CH8_LABEL	1080
#define IDC_CH8_TX	1081
#define IDC_CH8_TX_TONE	1082
#define IDC_CH8_RX	1083
#define IDC_CH8_RX_TONE	1084
#define IDC_CH8_STE	1085
#define IDC_CH8_CCT	1086

#define IDC_CH9_LABEL	1090
#define IDC_CH9_TX	1091
#define IDC_CH9_TX_TONE	1092
#define IDC_CH9_RX	1093
#define IDC_CH9_RX_TONE	1094
#define IDC_CH9_STE	1095
#define IDC_CH9_CCT	1096

#define IDC_CH10_LABEL	  1100
#define IDC_CH10_TX	  1101
#define IDC_CH10_TX_TONE  1102
#define IDC_CH10_RX       1103
#define IDC_CH10_RX_TONE  1104
#define IDC_CH10_STE	  1105
#define IDC_CH10_CCT	  1106

#define IDC_CH11_LABEL	  1110
#define IDC_CH11_TX	  1111
#define IDC_CH11_TX_TONE  1112
#define IDC_CH11_RX       1113
#define IDC_CH11_RX_TONE  1114
#define IDC_CH11_STE	  1115
#define IDC_CH11_CCT	  1116

#define IDC_CH12_LABEL	  1120
#define IDC_CH12_TX	  1121
#define IDC_CH12_TX_TONE  1122
#define IDC_CH12_RX       1123
#define IDC_CH12_RX_TONE  1124
#define IDC_CH12_STE	  1125
#define IDC_CH12_CCT	  1126

#define IDC_CH13_LABEL	  1130
#define IDC_CH13_TX	  1131
#define IDC_CH13_TX_TONE  1132
#define IDC_CH13_RX       1133
#define IDC_CH13_RX_TONE  1134
#define IDC_CH13_STE	  1135
#define IDC_CH13_CCT	  1136

#define IDC_CH14_LABEL	  1140
#define IDC_CH14_TX	  1141
#define IDC_CH14_TX_TONE  1142
#define IDC_CH14_RX       1143
#define IDC_CH14_RX_TONE  1144
#define IDC_CH14_STE	  1145
#define IDC_CH14_CCT	  1146

#define IDC_CH15_LABEL	  1150
#define IDC_CH15_TX	  1151
#define IDC_CH15_TX_TONE  1152
#define IDC_CH15_RX       1153
#define IDC_CH15_RX_TONE  1154
#define IDC_CH15_STE	  1155
#define IDC_CH15_CCT	  1156

#define IDC_CH16_LABEL	  1160
#define IDC_CH16_TX	  1161
#define IDC_CH16_TX_TONE  1162
#define IDC_CH16_RX       1163
#define IDC_CH16_RX_TONE  1164
#define IDC_CH16_STE	  1165
#define IDC_CH16_CCT	  1166

#define CCT_COMBOBOX	        1201
#define SCAN_TYPE_COMBOBOX	1202
#define PRIO_CHANNEL_COMBOBOX	1203

/* CG DIALOG IDENTIFIERS */
#define CG_RB_0 3000
#define CG_RB_1 3001
#define CG_RB_2 3002
#define CG_RB_3 3003
#define CG_RB_4 3004
#define CG_RB_5 3005
#define CG_RB_6 3006
#define CG_RB_7 3007
#define CG_RB_8 3008
#define CG_RB_9 3009
#define CG_RB_10 3010
#define CG_RB_11 3011
#define CG_RB_12 3012
#define CG_RB_13 3013
#define CG_RB_14 3014
#define CG_RB_15 3015
#define CG_RB_16 3016
#define CG_RB_17 3017
#define CG_RB_18 3018
#define CG_RB_19 3019
#define CG_RB_20 3020
#define CG_RB_21 3021
#define CG_RB_22 3022
#define CG_RB_23 3023
#define CG_RB_24 3024
#define CG_RB_25 3025
#define CG_RB_26 3026
#define CG_RB_27 3027
#define CG_RB_28 3028
#define CG_RB_29 3029
#define CG_RB_30 3030
#define CG_RB_31 3031
#define CG_RB_32 3032
#define CG_RB_33 3033
#define CG_RB_34 3034
#define CG_RB_35 3035
#define CG_RB_36 3036
#define CG_RB_37 3037
#define CG_RB_38 3038
#define CG_RB_39 3039
#define CG_RB_40 3040
#define CG_RB_41 3041
#define CG_RB_42 3042
#define CG_RB_43 3043
#define CG_RB_44 3044
#define CG_RB_45 3045
#define CG_RB_46 3046
#define CG_RB_47 3047
#define CG_RB_48 3048
#define CG_RB_49 3049
#define CG_RB_50 3050
#define CG_RB_51 3051
#define CG_RB_52 3052
#define CG_RB_53 3053
#define CG_RB_54 3054
#define CG_RB_55 3055
#define CG_RB_56 3056
#define CG_RB_57 3057
#define CG_RB_58 3058
#define CG_RB_59 3059
#define CG_RB_60 3060
#define CG_RB_61 3061
#define CG_RB_62 3062
#define CG_RB_63 3063
#define CG_RB_64 3064
#define CG_RB_65 3065
#define CG_RB_66 3066
#define CG_RB_67 3067
#define CG_RB_68 3068
#define CG_RB_69 3069
#define CG_RB_70 3070
#define CG_RB_71 3071
#define CG_RB_72 3072
#define CG_RB_73 3073
#define CG_RB_74 3074
#define CG_RB_75 3075
#define CG_RB_76 3076
#define CG_RB_77 3077
#define CG_RB_78 3078
#define CG_RB_79 3079
#define CG_RB_80 3080
#define CG_RB_81 3081
#define CG_RB_82 3082
#define CG_RB_83 3083
#define CG_RB_84 3084
#define CG_RB_85 3085
#define CG_RB_86 3086
#define CG_RB_87 3087
#define CG_RB_88 3088
#define CG_RB_89 3089
#define CG_RB_90 3090
#define CG_RB_91 3091
#define CG_RB_92 3092
#define CG_RB_93 3093
#define CG_RB_94 3094
#define CG_RB_95 3095
#define CG_RB_96 3096
#define CG_RB_97 3097
#define CG_RB_98 3098
#define CG_RB_99 3099
#define CG_RB_100 3100
#define CG_RB_101 3101
#define CG_RB_102 3102
#define CG_RB_103 3103
#define CG_RB_104 3104
#define CG_RB_105 3105
#define CG_RB_106 3106
#define CG_RB_107 3107
#define CG_RB_108 3108
#define CG_RB_109 3109
#define CG_RB_110 3110
#define CG_RB_111 3111
#define CG_RB_112 3112
#define CG_RB_113 3113
#define CG_RB_114 3114
#define CG_RB_115 3115
#define CG_RB_116 3116
#define CG_RB_117 3117
#define CG_RB_118 3118
#define CG_RB_119 3119
#define CG_RB_120 3120
#define CG_RB_121 3121
#define CG_RB_122 3122
#define CG_RB_123 3123
#define CG_RB_124 3124
#define CG_RB_125 3125
#define CG_RB_126 3126
#define CG_RB_127 3127
#define CG_RB_128 3128
#define CG_RB_129 3129
#define CG_RB_130 3130
#define CG_RB_131 3131
#define CG_RB_132 3132
#define CG_RB_133 3133
#define CG_RB_134 3134
#define CG_RB_135 3135
#define CG_RB_136 3136
#define CG_RB_137 3137

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#define MSG_PRINT_HEADER WM_USER + 100
#define MSG_PRINT_NEXT MSG_PRINT_HEADER + 1
#define MSG_PRINT_CLEANUP MSG_PRINT_NEXT + 1

typedef struct {
    int nRxFrequency;       /* receive frequency */
    int nTxFrequency;       /* transmit frequency */
    int nRxCGCode;          /* receive channel guard code */
    int nTxCGCode;          /* transmit channel guard code */
    int bUseSTE;            /* use Squelch Tail Elimination */
    int bUseCCT;            /* use Carrier Control Timer */
} ChannelDataStruct;

typedef struct {
    int nCCTTimeCode;             /* Carrier Control Timer time index */
    int nChannelSpacingCode;      /* channel spacing index */
    int nReferenceFrequencyCode;  /* reference frequency index */
    int nScanTypeCode;            /* scan type code */
    int nPriorityChannelNumber;   /* priority channel number */
    int filler; /* was bIsUHF; */                  /* UHF flag */
} RadioDataStruct;

typedef struct {
    int *frequency;
    WNDPROC oldWindowProc;
} FreqEditDataStruct;

