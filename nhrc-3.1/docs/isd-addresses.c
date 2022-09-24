#include <stdio.h>

typedef unsigned short uint16;

uint16 reverse16(uint16 in)
{
    uint16 out = 0;
    uint16 bitmasks[] = {
        0x0001, 0x0002, 0x0004, 0x0008,
        0x0010, 0x0020, 0x0040, 0x0080,
        0x0100, 0x0200, 0x0400, 0x0800,
        0x1000, 0x2000, 0x4000, 0x8000};

    int i;
    int j;
    for (i=0; i<16; i++)
    {
        j = 15 - i;
        out |= (in & bitmasks[i]) ? bitmasks[j] : 0;
    }

    //printf("reverse16(%04x)=%04x\n", in, out);

    return out;
}


int main(int argc, char *argv[])
{
    printf("ISD address calculator.\n");
    printf("At 8KHz sampling rate, each address increment is 0.125 seconds.\n");
    printf("Messages start at 2.0 seconds to preserve room for the \"sound effects\".\n\n");

    //int message_lengths[] = {30, 30, 30, 30, 30, 30, 30, 30};
    int message_lengths[] = {8, 8, 8, 8};
    int num_messages = sizeof (message_lengths) / sizeof(int);

    int i;
    int last_start_ms = 2000;
    int message_len_ms;
    int increment_ms = 125;
    uint16 message_start;
    uint16 message_end;

    printf("Msg Len  Start   End  Start    End    Rev    Rev\n");
    printf(" #  Sec   Sec    Sec   Addr   Addr  Start    End\n\n");

    for (i=0; i<num_messages; i++)
    {
        message_len_ms = message_lengths[i] * 1000;
        message_start = last_start_ms / increment_ms;
        message_end = (last_start_ms + message_len_ms) / increment_ms -1;

        printf("%2.1d  %3d   %3d    %3d   %04x   %04x   %04x   %04x\n",
               i, message_lengths[i],
               last_start_ms / 1000,
               (last_start_ms + message_len_ms) / 1000,
               message_start, message_end,
               reverse16(message_start), reverse16(message_end));
        last_start_ms += message_len_ms;
    }





}
