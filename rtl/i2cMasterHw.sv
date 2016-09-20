//--------------------------------------------------------------------------------
// File Name:     i2cMasterHw.sv
// Project:       i2cMaster
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    16.07.2016 - created
//    23.07.2016 - beta version
//--------------------------------------------------------------------------------
// i2c Master with Avalon MM interface
// 
// top-level wrapper for qsys automatic signal recognition
//--------------------------------------------------------------------------------
module i2cMasterHw             
   #( parameter int CLK_MASTER_FRQ = 50_000_000,   // master clock (input clk) frequency
                int SCLK_I2C_FRQ   = 500_000 )     // desired i2c sclk frequency
    ( input  logic           csi_clk,
      input  logic           rsi_reset,   // async reset
      
      // avalon MM slave
      input  logic [ 1 : 0 ] avs_address,
      input  logic           avs_write,
      input  logic [ 7 : 0 ] avs_writedata,
      input  logic           avs_read,
      output logic [ 7 : 0 ] avs_readdata,
      // avalon interrupt
      output logic           ins_irq,
      
      // i2c lines
      inout  wire            coe_sdat,
      inout  wire            coe_sclk );  
   
   // generate reference ticks
   i2cMaster 
     #( .CLK_MASTER_FRQ ( CLK_MASTER_FRQ ),
        .SCLK_I2C_FRQ   ( SCLK_I2C_FRQ   ) )
   i2cMasterInst
      ( .clk       ( csi_clk       ),
        .reset     ( rsi_reset     ),
        .avsAdr    ( avs_address   ),
        .avsWr     ( avs_write     ),
        .avsWrData ( avs_writedata ),
        .avsRd     ( avs_read      ),
        .avsRdData ( avs_readdata  ),
        .insIrq    ( ins_irq       ),
        .sdat      ( coe_sdat      ),
        .sclk      ( coe_sclk      ) );
         
endmodule  









