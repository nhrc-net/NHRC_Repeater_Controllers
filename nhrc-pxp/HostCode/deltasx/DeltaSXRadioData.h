/******************************************************************************/
/* Delta SX Radio Programmer -- Copyright (C) 2004, NHRC LLC.                 */
/* this header file defines data specific to the GE Delta SX radio.           */
/******************************************************************************/

const long ifFrequencies[] = { 45000000, 57500000 };
const LPSTR ifFrequencyNames[] = { "45 MHz", "57.5 MHz" };

#define NUM_IF_FREQUENCIES 2

#define BAND_LOW 0
#define BAND_VHF_45 1
#define BAND_VHF_575 2
#define BAND_UHF 3

const LPSTR cctTimes[] = {
    "none",
    "0.5",
    "1.0",
    "1.5",
    "2.0",
    "2.5",
    "3.0"
};
#define NUM_CCT 7

// CG data.  Encoded.
//
// ok, this data is encoded as follows:
// 15    not used
// 14    not used
// 13    not used
// 12    indicates DCG when 1
// 11    not used
// 10    not used
// 9     extra fine bit
// 8     coarse CG MSB
// 7..4  course CG or DCG hex code high nibble
// 3..0  fine CG or DCG hex code low nibble  
const int txCgCodes[] = {
    0x0000, //  0 no CTCSS
    0x0017, //  1 67.0
    0x023d, //  2 71.9
    0x0032, //  3 74.4 
    0x0246, //  4 77.0
    0x025b, //  5 79.7
    0x0051, //  6 82.5
    0x0261, //  7 85.4
    0x007c, //  8 88.5
    0x0073, //  9 91.5
    0x0289, // 10 94.8
    0x0282, // 11 97.4
    0x009c, // 12 100.0
    0x0293, // 13 103.5
    0x00ab, // 14 107.2
    0x02a3, // 15 110.9
    0x00bc, // 16 114.8
    0x02b4, // 17 118.8
    0x02cd, // 18 123.0
    0x02c6, // 19 127.3
    0x02df, // 20 131.8
    0x00d9, // 21 136.5
    0x00d3, // 22 141.3
    0x0ed1, // 23 146.2
    0x0e71, // 24 151.4 
    0x02e1, // 25 156.7
    0x00fc, // 26 162.2
    0x00f7, // 27 167.9
    0x00f2, // 28 173.8
    0x010d, // 29 179.9
    0x0308, // 30 186.2
    0x0303, // 31 192.8
    0x011d, // 32 203.5
    0x0318, // 33 210.7
    0x1031, // 34 023
    0x1051, // 35 025
    0x1061, // 36 026
    0x1091, // 37 031
    0x10a1, // 38 032
    0x1032, // 39 043
    0x1072, // 40 047
    0x1092, // 41 051
    0x10c2, // 42 054
    0x1053, // 43 065
    0x1093, // 44 071
    0x10a3, // 45 072
    0x10b3, // 46 073
    0x10c3, // 47 074
    0x10c4, // 48 114
    0x10d4, // 49 115
    0x1003, // 50 116
    0x1055, // 51 125
    0x1095, // 52 131
    0x10a5, // 53 132
    0x10c5, // 54 134
    0x1036, // 55 143
    0x10a6, // 56 152
    0x10d6, // 57 155
    0x10e6, // 58 156
    0x1027, // 59 162
    0x1057, // 60 165
    0x10a7, // 61 172
    0x1026, // 62 174
    0x10d5, // 63 205
    0x1039, // 64 223
    0x1044, // 65 226
    0x103a, // 66 243
    0x10e7, // 67 244
    0x105a, // 68 245
    0x10e9, // 69 251
    0x1079, // 70 261
    0x10b8, // 71 263
    0x1097, // 72 265
    0x109b, // 73 271
    0x1076, // 74 306
    0x109c, // 75 311
    0x10dc, // 76 315
    0x109d, // 77 331
    0x104d, // 78 343
    0x106e, // 79 346
    0x109e, // 80 351
    0x1085, // 81 364
    0x1074, // 82 365
    0x10f8, // 83 371
    0x10f4, // 84 411
    0x1075, // 85 412
    0x10b5, // 86 413
    0x10c9, // 87 423
    0x102b, // 88 431
    0x10eb, // 89 432
    0x1029, // 90 445
    0x10f9, // 91 464
    0x10e2, // 92 465
    0x1046, // 93 466
    0x10f6, // 94 503
    0x1049, // 95 506
    0x1037, // 96 516
    0x1017, // 97 532
    0x10fc, // 98 546
    0x107c, // 99 565
    0x10b6, // 100 606
    0x10ca, // 101 612
    0x10d3, // 102 624
    0x10f1, // 103 627
    0x1099, // 104 631
    0x1035, // 105 632
    0x1037, // 106 654
    0x103f, // 107 662
    0x104e, // 108 664
    0x1086, // 109 703
    0x10e5, // 110 712
    0x10d9, // 111 723
    0x1040, // 112 731
    0x1047, // 113 732
    0x1063, // 114 734
    0x10ac, // 115 743
    0x10e3, // 116 754
    0x10e1, // 117 036*
    0x10b2, // 118 053*
    0x1025, // 119 122*
    0x1056, // 120 145*
    0x10a8, // 121 212*
    0x1059, // 122 225*
    0x106a, // 123 246*
    0x10aa, // 124 252*
    0x10da, // 125 255*
    0x106b, // 126 266*
    0x10cb, // 127 274*
    0x105d, // 128 325*
    0x10ad, // 129 332*
    0x10ee, // 130 356*
    0x1030, // 131 446*
    0x1050, // 132 452*
    0x1060, // 133 454*
    0x1070, // 134 455*
    0x1080, // 135 462*
    0x1090, // 136 523*
    0x10a0};// 137 526*

const int txCgCodesInverted[] = {
    0x0000, //  0 no CTCSS
    0x0017, //  1 67.0
    0x023d, //  2 71.9
    0x0032, //  3 74.4 
    0x0246, //  4 77.0
    0x025b, //  5 79.7
    0x0051, //  6 82.5
    0x0261, //  7 85.4
    0x007c, //  8 88.5
    0x0073, //  9 91.5
    0x0289, // 10 94.8
    0x0282, // 11 97.4
    0x009c, // 12 100.0
    0x0293, // 13 103.5
    0x00ab, // 14 107.2
    0x02a3, // 15 110.9
    0x00bc, // 16 114.8
    0x02b4, // 17 118.8
    0x02cd, // 18 123.0
    0x02c6, // 19 127.3
    0x02df, // 20 131.8
    0x00d9, // 21 136.5
    0x00d3, // 22 141.3
    0x0ed1, // 23 146.2
    0x0e71, // 24 151.4 
    0x02e1, // 25 156.7
    0x00fc, // 26 162.2
    0x00f7, // 27 167.9
    0x00f2, // 28 173.8
    0x010d, // 29 179.9
    0x0308, // 30 186.2
    0x0303, // 31 192.8
    0x011d, // 32 203.5
    0x0318, // 33 210.7
    0x1072, // 34 023
    0x10e7, // 35 025
    0x10f9, // 36 026
    0x10f1, // 37 031
    0x1092, // 38 032
    0x1029, // 39 043
    0x1031, // 40 047
    0x10a1, // 41 051
    0x10b5, // 42 054
    0x109b, // 43 065
    0x1076, // 44 071
    0x105a, // 45 072
    0x1049, // 46 073
    0x1026, // 47 074
    0x10e5, // 48 114
    0x10a6, // 49 115
    0x10e3, // 50 116
    0x1074, // 51 125
    0x1085, // 52 131
    0x10fc, // 53 132
    0x1039, // 54 134
    0x1075, // 55 143
    0x10d4, // 56 152
    0x1040, // 57 155
    0x1097, // 58 156
    0x10f6, // 59 162
    0x10e9, // 60 165
    0x10e1, // 61 172
    0x10c3, // 62 174
    0x10b8, // 63 205
    0x10c5, // 64 223
    0x10f4, // 65 226
    0x109e, // 66 243
    0x1051, // 67 244
    0x10a3, // 68 245
    0x1057, // 69 251
    0x1047, // 70 261
    0x10d5, // 71 263
    0x10e6, // 72 265
    0x1053, // 73 271
    0x1093, // 74 306
    0x104e, // 75 311
    0x10c9, // 76 315
    0x10e2, // 77 331
    0x1017, // 78 343
    0x10ca, // 79 346
    0x103a, // 80 351
    0x1095, // 81 364
    0x1055, // 82 365
    0x1063, // 83 371
    0x1044, // 84 411
    0x1036, // 85 412
    0x10c2, // 86 413
    0x10dc, // 87 423
    0x10d9, // 88 431
    0x1073, // 89 432
    0x1032, // 90 445
    0x1061, // 91 464
    0x109d, // 92 465
    0x103f, // 93 466
    0x1027, // 94 503
    0x10b3, // 95 506
    0x10eb, // 96 516
    0x104d, // 97 532
    0x10a5, // 98 546
    0x1086, // 99 565
    0x1099, // 100 606
    0x106e, // 101 612
    0x1035, // 102 624
    0x1091, // 103 627
    0x10b6, // 104 631
    0x10d3, // 105 632
    0x10ac, // 106 654
    0x1046, // 107 662
    0x109c, // 108 664
    0x107c, // 109 703
    0x10c4, // 110 712
    0x102b, // 111 723
    0x10d6, // 112 731
    0x1079, // 113 732
    0x10f8, // 114 734
    0x1037, // 115 743
    0x1003, // 116 754
    0x10a7, // 117 036*
    0x1050, // 118 053*
    0x1059, // 119 122*
    0x10cb, // 120 145*
    0x10ee, // 121 212*
    0x1025, // 122 225*
    0x1090, // 123 246*
    0x1080, // 124 252*
    0x1030, // 125 255*
    0x1060, // 126 266*
    0x1056, // 127 274*
    0x10a0, // 128 325*
    0x1070, // 129 332*
    0x10a8, // 130 356*
    0x10da, // 131 446*
    0x10b2, // 132 452*
    0x106b, // 133 454*
    0x10ad, // 134 455*
    0x10aa, // 135 462*
    0x106a, // 136 523*
    0x105d};// 137 526*

const int rxCgCodes[] = {
    0x0000, //  0 no CTCSS
    0x0017, //  1 67.0
    0x003e, //  2 71.9
    0x0032, //  3 74.4 
    0x0047, //  4 77.0
    0x005c, //  5 79.7
    0x0051, //  6 82.5
    0x0067, //  7 85.4
    0x007c, //  8 88.5
    0x0073, //  9 91.5
    0x008a, // 10 94.8
    0x0083, // 11 97.4
    0x009c, // 12 100.0
    0x0094, // 13 103.5
    0x00ab, // 14 107.2
    0x00a3, // 15 110.9
    0x00bc, // 16 114.8
    0x00b4, // 17 118.8
    0x00cd, // 18 123.0
    0x00c6, // 19 127.3
    0x00df, // 20 131.8
    0x00d9, // 21 136.5
    0x00d3, // 22 141.3
    0x00ed, // 23 146.2
    0x00e7, // 24 151.4 
    0x00e2, // 25 156.7
    0x00fc, // 26 162.2
    0x00f7, // 27 167.9
    0x00f2, // 28 173.8
    0x010d, // 29 179.9
    0x0108, // 30 186.2
    0x0104, // 31 192.8
    0x011d, // 32 203.5
    0x0119, // 33 210.7
    0x1031, // 34 023
    0x1051, // 35 025
    0x1061, // 36 026
    0x1091, // 37 031
    0x10a1, // 38 032
    0x1032, // 39 043
    0x1072, // 40 047
    0x1092, // 41 051
    0x10c2, // 42 054
    0x1053, // 43 065
    0x1093, // 44 071
    0x10a3, // 45 072
    0x10b3, // 46 073
    0x10c3, // 47 074
    0x10c4, // 48 114
    0x10d4, // 49 115
    0x1003, // 50 116
    0x1055, // 51 125
    0x1095, // 52 131
    0x10a5, // 53 132
    0x10c5, // 54 134
    0x1036, // 55 143
    0x10a6, // 56 152
    0x10d6, // 57 155
    0x10e6, // 58 156
    0x1027, // 59 162
    0x1057, // 60 165
    0x10a7, // 61 172
    0x1026, // 62 174
    0x10d5, // 63 205
    0x1039, // 64 223
    0x1044, // 65 226
    0x103a, // 66 243
    0x10e7, // 67 244
    0x105a, // 68 245
    0x10e9, // 69 251
    0x1079, // 70 261
    0x10b8, // 71 263
    0x1097, // 72 265
    0x109b, // 73 271
    0x1076, // 74 306
    0x109c, // 75 311
    0x10dc, // 76 315
    0x109d, // 77 331
    0x104d, // 78 343
    0x106e, // 79 346
    0x109e, // 80 351
    0x1085, // 81 364
    0x1074, // 82 365
    0x10f8, // 83 371
    0x10f4, // 84 411
    0x1075, // 85 412
    0x10b5, // 86 413
    0x10c9, // 87 423
    0x102b, // 88 431
    0x10eb, // 89 432
    0x1029, // 90 445
    0x10f9, // 91 464
    0x10e2, // 92 465
    0x1046, // 93 466
    0x10f6, // 94 503
    0x1049, // 95 506
    0x1037, // 96 516
    0x1017, // 97 532
    0x10fc, // 98 546
    0x107c, // 99 565
    0x10b6, // 100 606
    0x10ca, // 101 612
    0x10d3, // 102 624
    0x10f1, // 103 627
    0x1099, // 104 631
    0x1035, // 105 632
    0x1037, // 106 654
    0x103f, // 107 662
    0x104e, // 108 664
    0x1086, // 109 703
    0x10e5, // 110 712
    0x10d9, // 111 723
    0x1040, // 112 731
    0x1047, // 113 732
    0x1063, // 114 734
    0x10ac, // 115 743
    0x10e3, // 116 754
    0x10e1, // 117 036*
    0x10b2, // 118 053*
    0x1025, // 119 122*
    0x1056, // 120 145*
    0x10a8, // 121 212*
    0x1059, // 122 225*
    0x106a, // 123 246*
    0x10aa, // 124 252*
    0x10da, // 125 255*
    0x106b, // 126 266*
    0x10cb, // 127 274*
    0x105d, // 128 325*
    0x10ad, // 129 332*
    0x10ee, // 130 356*
    0x1030, // 131 446*
    0x1050, // 132 452*
    0x1060, // 133 454*
    0x1070, // 134 455*
    0x1080, // 135 462*
    0x1090, // 136 523*
    0x10a0};// 137 526*

const int rxCgCodesInverted[] = {
    0x0000, //  0 no CTCSS
    0x0017, //  1 67.0
    0x003e, //  2 71.9
    0x0032, //  3 74.4 
    0x0047, //  4 77.0
    0x005c, //  5 79.7
    0x0051, //  6 82.5
    0x0067, //  7 85.4
    0x007c, //  8 88.5
    0x0073, //  9 91.5
    0x008a, // 10 94.8
    0x0083, // 11 97.4
    0x009c, // 12 100.0
    0x0094, // 13 103.5
    0x00ab, // 14 107.2
    0x00a3, // 15 110.9
    0x00bc, // 16 114.8
    0x00b4, // 17 118.8
    0x00cd, // 18 123.0
    0x00c6, // 19 127.3
    0x00df, // 20 131.8
    0x00d9, // 21 136.5
    0x00d3, // 22 141.3
    0x00ed, // 23 146.2
    0x00e7, // 24 151.4 
    0x00e2, // 25 156.7
    0x00fc, // 26 162.2
    0x00f7, // 27 167.9
    0x00f2, // 28 173.8
    0x010d, // 29 179.9
    0x0108, // 30 186.2
    0x0104, // 31 192.8
    0x011d, // 32 203.5
    0x0119, // 33 210.7
    0x1072, // 34 023
    0x10e7, // 35 025
    0x10f9, // 36 026
    0x10f1, // 37 031
    0x1092, // 38 032
    0x1029, // 39 043
    0x1031, // 40 047
    0x10a1, // 41 051
    0x10b5, // 42 054
    0x109b, // 43 065
    0x1076, // 44 071
    0x105a, // 45 072
    0x1049, // 46 073
    0x1026, // 47 074
    0x10e5, // 48 114
    0x10a6, // 49 115
    0x10e3, // 50 116
    0x1074, // 51 125
    0x1085, // 52 131
    0x10fc, // 53 132
    0x1039, // 54 134
    0x1075, // 55 143
    0x10d4, // 56 152
    0x1040, // 57 155
    0x1097, // 58 156
    0x10f6, // 59 162
    0x10e9, // 60 165
    0x10e1, // 61 172
    0x10c3, // 62 174
    0x10b8, // 63 205
    0x10c5, // 64 223
    0x10f4, // 65 226
    0x109e, // 66 243
    0x1051, // 67 244
    0x10a3, // 68 245
    0x1057, // 69 251
    0x1047, // 70 261
    0x10d5, // 71 263
    0x10e6, // 72 265
    0x1053, // 73 271
    0x1093, // 74 306
    0x104e, // 75 311
    0x10c9, // 76 315
    0x10e2, // 77 331
    0x1017, // 78 343
    0x10ca, // 79 346
    0x103a, // 80 351
    0x1095, // 81 364
    0x1055, // 82 365
    0x1063, // 83 371
    0x1044, // 84 411
    0x1036, // 85 412
    0x10c2, // 86 413
    0x10dc, // 87 423
    0x10d9, // 88 431
    0x1073, // 89 432
    0x1032, // 90 445
    0x1061, // 91 464
    0x109d, // 92 465
    0x103f, // 93 466
    0x1027, // 94 503
    0x10b3, // 95 506
    0x10eb, // 96 516
    0x104d, // 97 532
    0x10a5, // 98 546
    0x1086, // 99 565
    0x1099, // 100 606
    0x106e, // 101 612
    0x1035, // 102 624
    0x1091, // 103 627
    0x10b6, // 104 631
    0x10d3, // 105 632
    0x10ac, // 106 654
    0x1046, // 107 662
    0x109c, // 108 664
    0x107c, // 109 703
    0x10c4, // 110 712
    0x102b, // 111 723
    0x10d6, // 112 731
    0x1079, // 113 732
    0x10f8, // 114 734
    0x1037, // 115 743
    0x1003, // 116 754
    0x10a7, // 117 036*
    0x1050, // 118 053*
    0x1059, // 119 122*
    0x10cb, // 120 145*
    0x10ee, // 121 212*
    0x1025, // 122 225*
    0x1090, // 123 246*
    0x1080, // 124 252*
    0x1030, // 125 255*
    0x1060, // 126 266*
    0x1056, // 127 274*
    0x10a0, // 128 325*
    0x1070, // 129 332*
    0x10a8, // 130 356*
    0x10da, // 131 446*
    0x10b2, // 132 452*
    0x106b, // 133 454*
    0x10ad, // 134 455*
    0x10aa, // 135 462*
    0x106a, // 136 523*
    0x105d};// 137 526*

const LPSTR cgNames[] = {
    "None",  //   0
    "67.0",  //   1
    "71.9",  //   2
    "74.4",  //   3
    "77.0",  //   4
    "79.7",  //   5
    "82.5",  //   6
    "85.4",  //   7
    "88.5",  //   8
    "91.5",  //   9
    "94.8",  //  10
    "97.4",  //  11
    "100.0", //  12
    "103.5", //  13
    "107.2", //  14
    "110.9", //  15
    "114.8", //  16
    "118.8", //  17
    "123.0", //  18
    "127.3", //  19
    "131.8", //  20
    "136.5", //  21
    "141.3", //  22
    "146.2", //  23
    "151.4", //  24
    "156.7", //  25
    "162.2", //  26
    "167.9", //  27
    "173.8", //  28
    "179.9", //  29
    "186.2", //  30
    "192.8", //  31
    "203.5", //  32
    "210.7", //  33
    "023",   //  34
    "025",   //  35
    "026",   //  36
    "031",   //  37
    "032",   //  38
    "043",   //  39
    "047",   //  40
    "051",   //  41
    "054",   //  42
    "065",   //  43
    "071",   //  44
    "072",   //  45
    "073",   //  46
    "074",   //  47
    "114",   //  48
    "115",   //  49
    "116",   //  50
    "125",   //  51
    "131",   //  52
    "132",   //  53
    "134",   //  54
    "143",   //  55
    "152",   //  56
    "155",   //  57
    "156",   //  58
    "162",   //  59
    "165",   //  60
    "172",   //  61
    "174",   //  62
    "205",   //  63
    "223",   //  64
    "226",   //  65
    "243",   //  66
    "244",   //  67
    "245",   //  68
    "251",   //  69
    "261",   //  70
    "263",   //  71
    "265",   //  72
    "271",   //  73
    "306",   //  74
    "311",   //  75
    "315",   //  76
    "331",   //  77
    "343",   //  78
    "346",   //  79
    "351",   //  80
    "364",   //  81
    "365",   //  82
    "371",   //  83
    "411",   //  84
    "412",   //  85
    "413",   //  86
    "423",   //  87
    "431",   //  88
    "432",   //  89
    "445",   //  90
    "464",   //  91
    "465",   //  92
    "466",   //  93
    "503",   //  94
    "506",   //  95
    "516",   //  96
    "532",   //  97
    "546",   //  98
    "565",   //  99
    "606",   // 100
    "612",   // 101
    "624",   // 102
    "627",   // 103
    "631",   // 104
    "632",   // 105
    "654",   // 106
    "662",   // 107
    "664",   // 108
    "703",   // 109
    "712",   // 110
    "723",   // 111
    "731",   // 112
    "732",   // 113
    "734",   // 114
    "743",   // 115
    "754",   // 116
    "036*",  // 117
    "053*",  // 118
    "122*",  // 119
    "145*",  // 120
    "212*",  // 121
    "225*",  // 122
    "246*",  // 123
    "252*",  // 124
    "255*",  // 125
    "266*",  // 126
    "274*",  // 127
    "325*",  // 128
    "332*",  // 129
    "356*",  // 130
    "446*",  // 131
    "452*",  // 132
    "454*",  // 133
    "455*",  // 134
    "462*",  // 135
    "523*",  // 136
    "526*"}; // 137

#define NUM_CG 138
#define FIRST_DCG 34

#define NUM_CHANNELS 16
