//--------------------------------------------------------------------------------
// File Name:     main.c
// Project:       i2cMaster
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    21.08.2016 - created
//--------------------------------------------------------------------------------
// NIOS example
// initialization audio codec SSM2603 on SoCKit board via I2C
//--------------------------------------------------------------------------------
#include <system.h>
#include <sys/alt_timestamp.h>
#include "audioCodec.h"

int main()
{
   alt_u32 time0, time1;

   alt_timestamp_start();
   time0 = alt_timestamp();

   ssm2603I2cInit( I2CMASTER_BASE, 0x1A, 1 ); // device adr - 0001_1010

   time1 = alt_timestamp();
   printf( "ticks spent = %u\n", ( unsigned int ) ( time1 - time0 ) );

   return 0;
}
