//--------------------------------------------------------------------------------
// File Name:     tb_i2cMaster.sv
// Project:       i2cMaster
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    23.07.2016 - created
//--------------------------------------------------------------------------------
// testbench for i2cMaster
// write and read operations
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module tb_i2cMaster ();

   localparam int T = 20;                      // 50 MHz        
   localparam int CLK_MASTER_FRQ = 50_000_000; // master clock (input clk) frequency
   localparam int SCLK_I2C_FRQ   = 500_000;    // desired i2c sclk frequency

   logic           clk;
   logic           reset;
   logic [ 1 : 0 ] avsAdr    = 2'b0;
   logic           avsWr     = 1'b0;  
   logic [ 7 : 0 ] avsWrData = 8'b0;
   logic           avsRd     = 1'b0;
   logic [ 7 : 0 ] avsRdData;
   logic           insIrq;
   
   wand            sdat;
   wand            sclk;   
   // pullup
   assign sdat = 1'b1;
   assign sclk = 1'b1;
   
   i2cMaster
     #( .CLK_MASTER_FRQ ( CLK_MASTER_FRQ ),
        .SCLK_I2C_FRQ   ( SCLK_I2C_FRQ   ) )
   uut
      ( .clk       ( clk       ),  
        .reset     ( reset     ),
        .avsAdr    ( avsAdr    ),
        .avsWr     ( avsWr     ),
        .avsWrData ( avsWrData ),
        .avsRd     ( avsRd     ),
        .avsRdData ( avsRdData ),
        .insIrq    ( insIrq  ),
        .sdat      ( sdat      ),
        .sclk      ( sclk      ) );
        
   // i2c slave control
   logic           slvClear;    // clear slave state
   int             slvStretch;  // number of clocks for stretching
   logic [ 7 : 0 ] slvByteWr;   // byte to slave for writing ( answer to master )
   logic [ 7 : 0 ] slvByteRd;   // reading byte from slave ( master wrote this byte )
   logic           slvAck;      // reading ack from slave
        
  i2cSlave i2cSlaveInst
      ( .clk        ( clk        ),
        .reset      ( reset      ),
        .slvClear   ( slvClear   ),
        .slvStretch ( slvStretch ),
        .slvByteWr  ( slvByteWr  ),
        .slvByteRd  ( slvByteRd  ),
        .slvAck     ( slvAck     ), 
        .sdat       ( sdat       ),
        .sclk       ( sclk       ) );
         
   always begin
      clk = 1'b1;
      #( T / 2 );
      clk = 1'b0;
      #( T / 2 );
   end
   
   initial begin   
      reset = 1'b1;
      #( 10 * T + T / 2 );
      reset = 1'b0;
   end
   
   // avalon write task
   task avmWrite( input logic [ 1 : 0 ] adr,
                  input logic [ 7 : 0 ] wrData );
      avsAdr    = adr;
      avsWr     = 1'b1;      
      avsWrData = wrData;
      # ( T );
      avsAdr    = 2'd0;
      avsWr     = 1'b0;      
      avsWrData = 8'b0;      
   endtask
   
   // avalon read task
   task avmRead( input  logic [ 1 : 0 ] adr,
                 output logic [ 7 : 0 ] rdData );
      avsAdr = adr;
      avsRd  = 1'b1;
      # ( T );
      avsAdr = 2'd0;
      avsRd  = 1'b0;
      rdData = avsRdData;      
   endtask
   
   logic [ 7 : 0 ] tbByteWr, tbByteRd;
   
   // stretched state check
   always_ff @( posedge clk )
      if ( uut.i2cControlInst.tickX4 & ~uut.i2cControlInst.eql )
         $display( "tb : stretched state detected at %0t ns", $time );
   
   // avalon emulation
   initial begin
      slvClear   = 1'b0;
      slvStretch = 0;
      slvByteWr  = 8'b0;
      
      @ ( negedge reset );
      @ ( negedge clk );
      # ( 10 * T );
      
      // WRITE OPERATION
      // soft reset
      avmWrite( 2'd0, 8'b0000_0001 );
      # ( 2 * T );
      // enable core and interrupts
      avmWrite( 2'd0, 8'b1100_0000 );
      # ( 3 * T );
      // write byte : dev adr + write bit
      tbByteWr = 8'b0011_0100;
      avmWrite( 2'd2, tbByteWr );
      # ( T );
      // command ( start + write + ack by slave + no stop )
      avmWrite( 3'd3, 8'b1100_0000 );
      # ( T );
      if ( ~uut.cmdBusy )
         $warning( "tb : wrong cmdBusy bit : %b", uut.cmdBusy );      
         
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      @ ( negedge clk );
      if ( ~uut.cmdWait )
         $warning( "tb : wrong cmdWait bit : %b", uut.cmdWait );
      avmRead( 2'd0, tbByteRd );
      // read status core
      if ( tbByteRd != 8'b1100_0000 )
         $warning( "tb : wrong status core : %b", tbByteRd );
      // read interrupt bit
      avmRead( 2'd1, tbByteRd );
      if ( tbByteRd != 8'b0000_0001 )
         $warning( "tb : wrong interrupt bit : %b", tbByteRd );
      // clear interrupt bit
      avmWrite( 2'd1, 8'b0000_0000 );
      avmRead( 2'd1, tbByteRd );
      if ( tbByteRd != 8'b0000_0000 )
         $warning( "tb : wrong interrupt bit : %b", tbByteRd );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
         
      // write byte: 7 bit reg adr + 1 bit tbByteRd
      tbByteWr = 8'b1011_1001;
      avmWrite( 2'd2, tbByteWr );
      // command ( no start + write + ack by slave + no stop )
      avmWrite( 3'd3, 8'b0100_0000 );
      # ( 10 * T );
      // check for busy bit
      avmRead( 2'd3, tbByteRd );
      if ( ~tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
         
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      
      // write byte: 8 bit tbByteRd
      tbByteWr = 8'b1010_0101;
      avmWrite( 2'd2, tbByteWr );
      // command ( no start + write + ack by slave + stop )
      avmWrite( 3'd3, 8'b0101_0000 );
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      
      // READ OPERATION
      # ( 250 * T );
      // write byte : dev adr + write bit
      tbByteWr = 8'b1011_1100;
      avmWrite( 2'd2, tbByteWr );
      // command ( start + write + ack by slave + no stop )
      avmWrite( 3'd3, 8'b1100_0000 ); 
      // disable interrupt
      avmWrite( 2'd0, 8'b1000_0000 );
      
      // wait without interrupt
      avmRead( 2'd1, tbByteRd );
      while ( tbByteRd != 8'b0000_0001 )
         avmRead( 2'd1, tbByteRd );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );     
      // clear interrupt bit
      avmWrite( 2'd1, 8'b0000_0000 );
      // enable interrupt
      avmWrite( 2'd0, 8'b1100_0000 );
      
      // write byte : reg adr
      tbByteWr = 8'b0011_0100;
      avmWrite( 2'd2, tbByteWr );
      // command ( no start + write + ack by slave + no stop )
      avmWrite( 3'd3, 8'b0100_0000 ); 
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      
      // write byte : dev adr + read bit
      tbByteWr = 8'b1011_1101;
      avmWrite( 2'd2, tbByteWr );
      // command ( start + write + ack by slave + no stop )
      avmWrite( 3'd3, 8'b1100_0000 );
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );         
         
      // write byte : dont care
      avmWrite( 2'd2, 8'b0000_1001 );
      tbByteWr = 8'b1101_0101;
      slvByteWr = tbByteWr;
      // command ( no start + read + ack by master + no stop )
      avmWrite( 3'd3, 8'b0010_0000 );   
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( ~tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      // read tbByteRd
      avmRead( 2'd2, tbByteRd );
      if ( tbByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", tbByteRd, tbByteWr );
      if ( slvAck )
         $warning( "tb : wrong ack bit : %b", slvAck );
      
      tbByteWr = 8'b0100_1001;
      slvByteWr = tbByteWr;
      // command ( no start + read + no ack by master + stop )
      avmWrite( 3'd3, 8'b0001_0000 );  
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      // read tbByteRd
      avmRead( 2'd2, tbByteRd );
      if ( tbByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", tbByteRd, tbByteWr );
      if ( ~slvAck )
         $warning( "tb : wrong ack bit : %b", slvAck );
         
      // CHECK STRETCHED MODE
      # ( 250 * T );
      slvStretch = 200;
      // write byte
      tbByteWr = 8'b1111_1010;
      avmWrite( 2'd2, tbByteWr );
      // command ( start + write + ack by slave + stop )
      avmWrite( 3'd3, 8'b1101_0000 ); 
      
      // wait for interrupt
      wait ( insIrq == 1'b1 ); 
      @ ( negedge clk );
      if ( slvByteRd != tbByteWr )
         $warning( "tb : slave / master bytes arent equal : %b / %b", slvByteRd, tbByteWr );
      // read status
      avmRead( 2'd3, tbByteRd );
      if ( tbByteRd[ 1 : 0 ] != 2'b00 )
         $warning( "tb : wrong cmdErr : %b", tbByteRd[ 1 : 0 ] );
      if ( tbByteRd[ 7 ] )
         $warning( "tb : wrong cmdBusy bit : %b", tbByteRd[ 7 ] );
      if ( tbByteRd[ 6 ] )
         $warning( "tb : wrong cmdWait bit : %b", tbByteRd[ 6 ] );
      
      $display( "tb : finished" );
   end
   
endmodule